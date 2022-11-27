import Foundation
import SwiftTypeReader
import TypeScriptAST

public final class CodeGenerator {
    public let context: Context
    public let typeMap: TypeMap
    private let emptyDecodeEvaluator: EmptyDecodeEvaluator

    public init(
        context: Context,
        typeMap: TypeMap = .default
    ) {
        self.context = context
        self.typeMap = typeMap
        self.emptyDecodeEvaluator = EmptyDecodeEvaluator(
            evaluator: context.evaluator,
            typeMap: typeMap
        )
    }

    public func generateTypeOwnDeclarations(type: any TypeDecl) throws -> TypeOwnDeclarations {
        return TypeOwnDeclarations(
            type: try generateTypeDeclaration(type: type, target: .entity),
            jsonType: try generateTypeDeclaration(type: type, target: .json),
            decodeFunction: try generateDecodeFunction(type: type)
        )
    }

    public func hasJSONType(type: any SType) throws -> Bool {
        return try !emptyDecodeEvaluator.evaluate(type)
    }

    public func hasJSONType(type: any TypeDecl) throws -> Bool {
        return try hasJSONType(type: type.declaredInterfaceType)
    }

    public func generateTypeDeclaration(type: any TypeDecl, target: GenerationTarget) throws -> TSTypeDecl {
        switch type {
        case let type as EnumDecl:
            return try EnumConverter(generator: self).transpile(type: type, target: target)
        case let type as StructDecl:
            return try StructConverter(generator: self).transpile(type: type, target: target)
        default:
            throw MessageError("unsupported type: \(type)")
        }
    }

    public func generateDecodeFunction(type: any TypeDecl) throws -> TSFunctionDecl? {
        guard try hasJSONType(type: type) else { return nil }

        switch type {
        case let type as EnumDecl:
            return try EnumConverter.DecodeFunc(generator: self, type: type).generate()
        case let type as StructDecl:
            return try StructConverter(generator: self).generateDecodeFunc(type: type)
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
            guard try hasJSONType(type: type) else {
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
