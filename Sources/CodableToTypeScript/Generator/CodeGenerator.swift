import Foundation
import SwiftTypeReader
import TypeScriptAST

public final class CodeGenerator {
    private final class RequestToken: HashableFromIdentity {
        unowned let gen: CodeGenerator
        init(gen: CodeGenerator) {
            self.gen = gen
        }
    }

    private var requestToken: RequestToken!
    public let context: Context
    public let typeMap: TypeMap
    private let typeConverterProvider: TypeConverterProvider

    public init(
        context: Context,
        typeConverterProvider: TypeConverterProvider = TypeConverterProvider()
    ) {
        self.context = context
        self.typeMap = typeConverterProvider.typeMap
        self.typeConverterProvider = typeConverterProvider
        self.requestToken = RequestToken(gen: self)
    }

    private func implConverter(for type: any SType) throws -> any TypeConverter {
        return try typeConverterProvider.provide(generator: self, type: type)
    }

    public func converter(for type: any SType) throws -> any TypeConverter {
        let impl = try self.implConverter(for: type)
        return ProxyConverterWrapper(gen: self, type: type, impl: impl)
    }

    private struct ProxyConverterWrapper: TypeConverter {
        var gen: CodeGenerator
        var type: any SType
        var impl: any TypeConverter

        func hasJSONType() throws -> Bool {
            return try gen.context.evaluator(
                HasJSONTypeRequest(token: gen.requestToken, type: type)
            )
        }
    }

    private struct HasJSONTypeRequest: Request {
        var token: RequestToken
        @AnyTypeStorage var type: any SType

        func evaluate(on evaluator: RequestEvaluator) throws -> Bool {
            do {
                let converter = try token.gen.implConverter(for: type)
                return try converter.hasJSONType()
            } catch {
                switch error {
                case is CycleRequestError: return true
                default: throw error
                }
            }
        }
    }

    public func generateTypeOwnDeclarations(type: any TypeDecl) throws -> TypeOwnDeclarations {
        return TypeOwnDeclarations(
            type: try generateTypeDeclaration(type: type, target: .entity),
            jsonType: try generateTypeDeclaration(type: type, target: .json),
            decodeFunction: try generateDecodeFunction(type: type)
        )
    }

    public func generateTypeDeclaration(type: any TypeDecl, target: GenerationTarget) throws -> TSTypeDecl {
        switch type {
        case let type as EnumDecl:
            return try OldEnumConverter(generator: self).transpile(type: type, target: target)
        case let type as StructDecl:
            return try OldStructConverter(generator: self).transpile(type: type, target: target)
        default:
            throw MessageError("unsupported type: \(type)")
        }
    }

    public func generateDecodeFunction(type: any TypeDecl) throws -> TSFunctionDecl? {
        guard try converter(for: type.declaredInterfaceType).hasJSONType() else { return nil }

        switch type {
        case let type as EnumDecl:
            return try OldEnumConverter.DecodeFunc(generator: self, type: type).generate()
        case let type as StructDecl:
            return try OldStructConverter(generator: self).generateDecodeFunc(type: type)
        default:
            throw MessageError("unsupported type: \(type)")
        }
    }

    public func generateTypeDeclarationFile(type: any TypeDecl) throws -> TSSourceFile {
        var decls: [any ASTNode] = []

        func walk(type: any TypeDecl) throws {
            decls += try generateTypeOwnDeclarations(type: type).decls

            for type in type.asNominalType?.types ?? [] {
                try walk(type: type)
            }
        }

        try walk(type: type)

        return TSSourceFile(decls)
    }

    public func transpileFieldTypeReference(
        type: any SType, target: GenerationTarget
    ) throws -> (type: any TSType, isOptionalField: Bool) {
        var type = type
        var isOptionalField = false
        if let (wrapped, _) = type.unwrapOptional(limit: 1) {
            type = wrapped
            isOptionalField = true
        }
        return (
            type: try transpileTypeReference(type, target: target),
            isOptionalField: isOptionalField
        )
    }

    public func transpileTypeReference(_ type: any SType, target: GenerationTarget) throws -> any TSType {
        if let (wrapped, _) = type.unwrapOptional(limit: nil) {
            return TSUnionType([
                try transpileTypeReference(wrapped, target: target),
                TSIdentType.null
            ])
        }
        if let (_, element) = type.asArray() {
            return TSArrayType(
                try transpileTypeReference(element, target: target)
            )
        }
        if let (_, value) = type.asDictionary() {
            return TSDictionaryType(
                try transpileTypeReference(value, target: target)
            )
        }
        if let mappedName = typeMap.map(repr: type.toTypeRepr(containsModule: false)) {
            let args = try transpileGenericArguments(type: type, target: target)
            return TSIdentType(mappedName, genericArgs: args)
        }

        let name = try transpileTypeName(type: type, target: target)
        let args = try transpileGenericArguments(type: type, target: target)

        return TSIdentType(name, genericArgs: args)
    }

    public func transpileGenericParameter(type: GenericParamDecl, target: GenerationTarget) throws -> String {
        return try transpileTypeName(type: type, target: target)
    }

    public func transpileGenericParameters(type: any TypeDecl, target: GenerationTarget) throws -> [String] {
        return try type.genericParams.items.map { (param) in
            try transpileGenericParameter(type: param, target: target)
        }
    }

    public func transpileGenericArguments(type: any SType, target: GenerationTarget) throws -> [any TSType] {
        guard let type = type.asNominal else { return [] }
        return try type.genericArgs.map { (type) in
            try transpileTypeReference(type, target: target)
        }
    }

    public func transpileTypeName(type: any SType, target: GenerationTarget) throws -> String {
        switch target {
        case .entity:
            return type.namePath().convert()
        case .json:
            guard try converter(for: type).hasJSONType() else {
                return try transpileTypeName(type: type, target: .entity)
            }
            let base = try transpileTypeName(type: type, target: .entity)
            return "\(base)_JSON"
        }
    }

    public func transpileTypeName(type: any TypeDecl, target: GenerationTarget) throws -> String {
        return try transpileTypeName(type: type.declaredInterfaceType, target: target)
    }

    func helperLibrary() -> HelperLibraryGenerator {
        return HelperLibraryGenerator(generator: self)
    }

    public func generateHelperLibrary() -> TSSourceFile {
        return helperLibrary().generate()
    }

    func decodeFunction() -> DecodeFunctionBuilder {
        return DecodeFunctionBuilder(generator: self)
    }

    public func generateDecodeFieldExpression(type: any SType, expr: any TSExpr) throws -> any TSExpr {
        return try decodeFunction().decodeField(type: type, expr: expr)
    }

    public func generateDecodeValueExpression(type: any SType, expr: any TSExpr) throws -> any TSExpr {
        return try decodeFunction().decodeValue(type: type, expr: expr)
    }
}
