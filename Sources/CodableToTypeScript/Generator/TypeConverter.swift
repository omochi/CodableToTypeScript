import SwiftTypeReader
import TSCodeModule

final class TypeConverter {
    enum TypeKind {
        case type
        case json
    }

    struct TypeResult {
        var typeDecl: TSTypeDecl
        var jsonDecl: TSTypeDecl?
        var decodeFunc: TSFunctionDecl?
        var nestedTypeDecls: [TSDecl]

        var decls: [TSDecl] {
            var decls: [TSDecl] = [
                .type(typeDecl)
            ]

            if let d = jsonDecl {
                decls.append(.type(d))
            }
            if let d = decodeFunc {
                decls.append(.function(d))
            }
            
            decls += nestedTypeDecls

            return decls
        }
    }

    init(typeMap: TypeMap) {
        self.typeMap = typeMap
        self.emptyDecodeEvaluator = EmptyDecodeEvaluator(typeMap: typeMap)
    }

    let typeMap: TypeMap
    private let emptyDecodeEvaluator: EmptyDecodeEvaluator

    func convert(type: SType) throws -> [TSDecl] {
        guard let type = type.regular else {
            return []
        }

        switch type {
        case .enum(let type):
            let result = try EnumConverter(converter: self).convert(type: type)
            return result.decls
        case .struct(let type):
            let result = try StructConverter(converter: self).convert(type: type)
            return result.decls
        case .protocol,
                .genericParameter:
            return []
        }
    }

    func convertNestedTypeDecls(type: SType) throws -> [TSDecl] {
        var decls: [TSDecl] = []

        guard let type = type.regular else {
            return decls
        }

        if !type.types.isEmpty {
            for nestedType in type.types {
                decls += try self.convert(type: nestedType)
            }
        }

        return decls
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
