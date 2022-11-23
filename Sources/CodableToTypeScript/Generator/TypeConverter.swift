import SwiftTypeReader
import TSCodeModule

final class TypeConverter {
    enum TypeKind {
        case type
        case json
    }

    init(context: Context, typeMap: TypeMap) {
        self.typeMap = typeMap
        self.emptyDecodeEvaluator = EmptyDecodeEvaluator(
            evaluator: context.evaluator,
            typeMap: typeMap
        )
    }

    private let typeMap: TypeMap
    private let emptyDecodeEvaluator: EmptyDecodeEvaluator

    func generateTypeOwnDeclarations(type: any TypeDecl) throws -> TypeOwnDeclarations {
        return TypeOwnDeclarations(
            type: try generateTypeDeclaration(type: type),
            jsonType: try generateJSONTypeDeclaration(type: type),
            decodeFunction: try generateDecodeFunction(type: type)
        )
    }

    func generateTypeDeclaration(type: any TypeDecl) throws -> TSTypeDecl {
        return try generateTypeDeclaration(type: type, kind: .type)
    }

    func generateJSONTypeDeclaration(type: any TypeDecl) throws -> TSTypeDecl? {
        if try hasEmptyDecoder(type: type) { return nil }
        return try generateTypeDeclaration(type: type, kind: .json)
    }

    private func generateTypeDeclaration(type: any TypeDecl, kind: TypeKind) throws -> TSTypeDecl {
        switch type {
        case let type as EnumDecl:
            return try EnumConverter(converter: self).transpile(type: type, kind: kind)
        case let type as StructDecl:
            return try StructConverter(converter: self).transpile(type: type, kind: kind)
        default:
            throw MessageError("unsupported type: \(type)")
        }
    }

    func generateDecodeFunction(type: any TypeDecl) throws -> TSFunctionDecl? {
        if try hasEmptyDecoder(type: type) { return nil }

        switch type {
        case let type as EnumDecl:
            return try EnumConverter.DecodeFunc(converter: self, type: type).generate()
        case let type as StructDecl:
            return try StructConverter(converter: self).generateDecodeFunc(type: type)
        default:
            throw MessageError("unsupported type: \(type)")
        }
    }

    func transpiledName(of type: any SType, kind: TypeKind) -> String {
        switch kind {
        case .type:
            return type.namePath().convert()
        case .json:
            let base = transpiledName(of: type, kind: .type)
            return jsonTypeName(base: base)
        }
    }

    func transpiledName(of type: any TypeDecl, kind: TypeKind) -> String {
        return transpiledName(of: type.declaredInterfaceType, kind: kind)
    }

    func jsonTypeName(base: String) -> String {
        return "\(base)_JSON"
    }

    func transpileFieldTypeReference(type: any SType, kind: TypeKind) throws -> (type: TSType, isOptionalField: Bool) {
        var type = type
        var isOptionalField = false
        if let (wrapped, _) = type.unwrapOptional(limit: 1) {
            type = wrapped
            isOptionalField = true
        }
        return (
            type: try transpileTypeReference(type, kind: kind),
            isOptionalField: isOptionalField
        )
    }

    func transpileTypeReference(_ type: any SType, kind: TypeKind) throws -> TSType {
        if let (wrapped, _) = type.unwrapOptional(limit: nil) {
            return .orNull(
                try transpileTypeReference(wrapped, kind: kind)
            )
        }
        if let (_, element) = type.asArray() {
            return .array(
                try transpileTypeReference(element, kind: kind)
            )
        }
        if let (_, value) = type.asDictionary() {
            return .dictionary(
                try transpileTypeReference(value, kind: kind)
            )
        }
        if let mappedName = typeMap.map(repr: type.toTypeRepr(containsModule: false)) {
            let args = try transpileGenericArguments(type: type, kind: kind)
            return .named(mappedName, genericArguments: args)
        }

        let name: String = try {
            var kind = kind
            if kind == .json,
               try hasEmptyDecoder(type: type)
            {
                kind = .type
            }
            return transpiledName(of: type, kind: kind)
        }()

        let args = try transpileGenericArguments(type: type, kind: kind)

        return .named(name, genericArguments: args)
    }

    func transpileGenericParameter(type: GenericParamDecl, kind: TypeKind) -> TSGenericParameter {
        let name = transpiledName(of: type, kind: kind)
        return TSGenericParameter(.init(name))
    }

    func transpileGenericParameters(type: any TypeDecl, kind: TypeKind) -> [TSGenericParameter] {
        return type.genericParams.items.map { (param) in
            transpileGenericParameter(type: param, kind: kind)
        }
    }

    func transpileGenericArguments(type: any SType, kind: TypeKind) throws -> [TSGenericArgument] {
        guard let type = type.asNominal else { return [] }
        return try type.genericArgs.map { (type) in
            let type = try transpileTypeReference(type, kind: kind)
            return TSGenericArgument(type)
        }
    }

    func hasEmptyDecoder(type: any SType) throws -> Bool {
        return try emptyDecodeEvaluator.evaluate(type)
    }

    func hasEmptyDecoder(type: any TypeDecl) throws -> Bool {
        return try hasEmptyDecoder(type: type.declaredInterfaceType)
    }

    func decodeFunction() -> DecodeFunctionBuilder {
        DecodeFunctionBuilder(converter: self)
    }

    func helperLibrary() -> HelperLibraryGenerator {
        HelperLibraryGenerator(converter: self)
    }
}
