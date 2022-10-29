import SwiftTypeReader
import TSCodeModule

struct TypeConverter {
    struct TypeInfoKey: Hashable {
        var location: Location
        var name: String

        init(location: Location, name: String) {
            self.location = location
            self.name = name
        }

        init(type: RegularType) {
            self.init(
                location: type.location,
                name: type.name
            )
        }
    }

    struct TypeInfo {
        var hasEmptyDecoder: Bool?
    }

    final class Cache {
        init() {}

        private var types: [TypeInfoKey: TypeInfo] = [:]

        func get(for type: RegularType) -> TypeInfo {
            let key = TypeInfoKey(type: type)
            return types[key] ?? .init()
        }

        func set(_ info: TypeInfo, for type: RegularType) {
            let key = TypeInfoKey(type: type)
            types[key] = info
        }

        func modify(for type: RegularType, body: (inout TypeInfo) -> Void) {
            var info = get(for: type)
            body(&info)
            set(info, for: type)
        }
    }

    struct TypeResult {
        var typeDecl: TSTypeDecl
        var jsonDecl: TSTypeDecl
        var decodeFunc: TSFunctionDecl
        var nestedTypeDecls: [TSDecl]

        var decls: [TSDecl] {
            var decls: [TSDecl] = [
                .type(typeDecl),
                .type(jsonDecl),
                .function(decodeFunc)
            ]
            
            decls += nestedTypeDecls

            return decls
        }
    }

    var typeMap: TypeMap
    private let cache = Cache()

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

    func transpiledName(of type: SType, kind: NameKind) -> String {
        var path = namePath(type: type)
        switch kind {
        case .type: break
        case .json:
            switch type.regular {
            case .struct,
                .enum:
                path.items.append("JSON")
            default:
                break
            }
        case .decode:
            path.items.append("decode")
        }
        return path.convert()
    }

    private func namePath(type: SType) -> NamePath {
        var specifier = type.asSpecifier()
        _ = specifier.removeModuleElement()

        var parts: [String] = []
        for element in specifier.elements {
            parts.append(element.name)
        }

        return NamePath(parts)
    }

    enum TypeKind {
        case type
        case json

        func toNameKind() -> NameKind {
            switch self {
            case .type: return .type
            case .json: return .json
            }
        }
    }

    enum NameKind {
        case type
        case json
        case decode
    }

    func transpileTypeReference(_ type: SType, kind: TypeKind) throws -> TSType {
        let (unwrappedFieldType, isWrapped) = try Utils.unwrapOptional(type, limit: nil)
        if isWrapped {
            let wrapped = try transpileTypeReference(
                unwrappedFieldType,
                kind: kind
            )
            return .union([wrapped, .named("null")])
        } else if let st = type.struct,
                  st.module?.name == "Swift",
                  st.name == "Array",
                  try st.genericArguments().count >= 1
        {
            let element = try transpileTypeReference(
                try st.genericArguments()[0],
                kind: kind
            )
            return .array(element)
        } else if let st = type.struct,
                  st.module?.name == "Swift",
                  st.name == "Dictionary",
                  try st.genericArguments().count >= 2
        {
            let element = try transpileTypeReference(
                try st.genericArguments()[1],
                kind: kind
            )
            return .dictionary(element)
        }

        if let mappedName = typeMap.map(specifier: type.asSpecifier()) {
            let args = try transpileGenericArguments(type: type)
            return .named(mappedName, genericArguments: args)
        }

        let name = transpiledName(of: type, kind: kind.toNameKind())

        let args = try transpileGenericArguments(type: type)

        return .named(name, genericArguments: args)
    }

    func transpileFieldTypeReference(fieldType: SType, kind: TypeKind) throws -> TSType {
        var kind = kind
        switch kind {
        case .type: break
        case .json:
            if try hasEmptyDecoder(type: fieldType) {
                kind = .type
            }
        }
        return try transpileTypeReference(fieldType, kind: kind)
    }

    func transpileGenericParameters(type: SType) -> [TSGenericParameter] {
        guard let type = type.regular else { return .init() }

        return type.genericParameters.map { (param) in
            TSGenericParameter(.named(param.name))
        }
    }

    func transpileGenericArguments(type: SType) throws -> [TSGenericArgument] {
        return try type.genericArguments().map { (arg) in
            TSGenericArgument(.named(arg.name))
        }
    }

    func isStringRawValueType(type: SType) throws -> Bool {
        guard let type = type.regular else { return false }
        return try type.inheritedTypes().first?.name == "String"
    }

    func hasEmptyDecoder(type: SType) throws -> Bool {
        guard let type = type.regular else { return true }

        if let cache = cache.get(for: type).hasEmptyDecoder {
            return cache
        }

        let result = try _hasEmptyDecoder(type: type)
        cache.modify(for: type) { $0.hasEmptyDecoder = result }
        return result
    }

    private func _hasEmptyDecoder(type: RegularType) throws -> Bool {
        if let _ = typeMap.map(specifier: type.asSpecifier()) {
            /*
             mapped type doesn't have decoder
             */
            return true
        }

        switch type {
        case .enum(let type):
            if type.caseElements.isEmpty { return true }
            if try isStringRawValueType(type: .enum(type)) { return true }
            return false
        case .struct(let type):
            for field in type.storedProperties {
                if try !hasEmptyDecoder(type: try field.type()) { return false }
            }
            return true
        case .genericParameter, .protocol:
            return true
        }
    }
}
