import SwiftTypeReader
import TSCodeModule

final class TypeConverter {
    enum TypeKind {
        case type
        case json
    }

    init(typeMap: TypeMap) {
        self.typeMap = typeMap
        self.emptyDecodeEvaluator = EmptyDecodeEvaluator(typeMap: typeMap)
    }

    let typeMap: TypeMap
    private let emptyDecodeEvaluator: EmptyDecodeEvaluator

    func generateTypeOwnDeclarations(type: SType) throws -> TypeOwnDeclarations {
        return TypeOwnDeclarations(
            type: try generateTypeDeclaration(type: type),
            jsonType: try generateJSONTypeDeclaration(type: type),
            decodeFunction: try generateDecodeFunction(type: type)
        )
    }

    func generateTypeDeclaration(type: SType) throws -> TSTypeDecl {
        return try generateTypeDeclaration(type: type, kind: .type)
    }

    func generateJSONTypeDeclaration(type: SType) throws -> TSTypeDecl? {
        if try hasEmptyDecoder(type: type) { return nil }
        return try generateTypeDeclaration(type: type, kind: .json)
    }

    private func generateTypeDeclaration(type: SType, kind: TypeKind) throws -> TSTypeDecl {
        guard let type = type.regular else {
            throw MessageError("unresolved type: \(type)")
        }

        switch type {
        case .enum(let type):
            return try EnumConverter(converter: self).transpile(type: type, kind: kind)
        case .struct(let type):
            return try StructConverter(converter: self).transpile(type: type, kind: kind)
        case .protocol, .genericParameter:
            throw MessageError("unsupported type: \(type)")
        }
    }

    func generateDecodeFunction(type: SType) throws -> TSFunctionDecl? {
        if try hasEmptyDecoder(type: type) { return nil }

        guard let type = type.regular else {
            throw MessageError("unresolved type: \(type)")
        }

        switch type {
        case .enum(let type):
            return try EnumConverter.DecodeFunc(converter: self, type: type).generate()
        case .struct(let type):
            return try StructConverter(converter: self).generateDecodeFunc(type: type)
        case .protocol, .genericParameter:
            throw MessageError("unsupported type: \(type)")
        }
    }

    func transpiledName(of type: SType, kind: TypeKind) -> String {
        switch kind {
        case .type:
            return type.namePath().convert()
        case .json:
            let base = transpiledName(of: type, kind: .type)
            return jsonTypeName(base: base)
        }
    }

    func jsonTypeName(base: String) -> String {
        return "\(base)_JSON"
    }

    func transpileFieldTypeReference(type: SType, kind: TypeKind) throws -> (type: TSType, isOptionalField: Bool) {
        var type = type
        var isOptionalField = false
        if let (wrapped, _) = try type.unwrapOptional(limit: 1) {
            type = wrapped
            isOptionalField = true
        }
        return (
            type: try transpileTypeReference(type, kind: kind),
            isOptionalField: isOptionalField
        )
    }

    func transpileTypeReference(_ type: SType, kind: TypeKind) throws -> TSType {
        if let (wrapped, _) = try type.unwrapOptional(limit: nil) {
            return .orNull(
                try transpileTypeReference(wrapped, kind: kind)
            )
        }
        if let (_, element) = try type.asArray() {
            return .array(
                try transpileTypeReference(element, kind: kind)
            )
        }
        if let (_, value) = try type.asDictionary() {
            return .dictionary(
                try transpileTypeReference(value, kind: kind)
            )
        }
        if let mappedName = typeMap.map(specifier: type.asSpecifier()) {
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

    func transpileGenericParameter(type: SType, kind: TypeKind) -> TSGenericParameter {
        let name = transpiledName(of: type, kind: kind)
        return TSGenericParameter(.init(name))
    }

    func transpileGenericParameters(type: SType, kind: TypeKind) -> [TSGenericParameter] {
        guard let type = type.regular else { return .init() }

        return type.genericParameters.map { (param) in
            transpileGenericParameter(type: .genericParameter(param), kind: kind)
        }
    }

    func transpileGenericArguments(type: SType, kind: TypeKind) throws -> [TSGenericArgument] {
        return try type.genericArguments().map { (type) in
            let type = try transpileTypeReference(type, kind: kind)
            return TSGenericArgument(type)
        }
    }

    func hasEmptyDecoder(type: SType) throws -> Bool {
        return try emptyDecodeEvaluator.evaluate(type: type)
    }

    func decodeFunction() -> DecodeFunctionBuilder {
        DecodeFunctionBuilder(converter: self)
    }

    func helperLibrary() -> HelperLibraryGenerator {
        HelperLibraryGenerator(converter: self)
    }
}
