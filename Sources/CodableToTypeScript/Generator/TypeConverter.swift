import SwiftTypeReader
import TSCodeModule

struct TypeConverter {
    struct TypeInfoKey: Hashable {
        var location: Location?
        var name: String
        var genericArguments: [TypeInfoKey]

        init(
            location: Location?,
            name: String,
            genericArguments: [TypeInfoKey]
        ) {
            self.location = location
            self.name = name
            self.genericArguments = genericArguments
        }

        init(type: SType) throws {
            let location = type.regular?.location
            let name = type.name
            let genericArguments: [TypeInfoKey] = try type.genericArguments().map { (arg) in
                try TypeInfoKey(type: arg)
            }
            self.init(
                location: location,
                name: name,
                genericArguments: genericArguments
            )
        }
    }

    struct TypeInfo {
        var hasEmptyDecoder: Bool?
    }

    final class Cache {
        init() {}

        private var types: [TypeInfoKey: TypeInfo] = [:]

        func get(for type: SType) throws -> TypeInfo {
            let key = try TypeInfoKey(type: type)
            return types[key] ?? .init()
        }

        func set(_ info: TypeInfo, for type: SType) throws {
            let key = try TypeInfoKey(type: type)
            types[key] = info
        }

        func modify(for type: SType, body: (inout TypeInfo) -> Void) throws {
            var info = try get(for: type)
            body(&info)
            try set(info, for: type)
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

    func transpiledName(of type: SType, kind: TypeKind) -> String {
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

        let name = transpiledName(of: type, kind: kind)

        let args = try transpileGenericArguments(type: type)

        return .named(name, genericArguments: args)
    }

    func transpileFieldTypeReference(type: SType, kind: TypeKind) throws -> (type: TSType, isOptionalField: Bool) {
        let (type, optionalDepth) = try unwrapOptional(type: type, limit: 1)
        var kind = kind
        switch kind {
        case .type: break
        case .json:
            if try hasEmptyDecoder(type: type) {
                kind = .type
            }
        }
        return (
            type: try transpileTypeReference(type, kind: kind),
            isOptionalField: optionalDepth > 0
        )
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
        guard let _ = type.regular else { return true }

        if let cache = try cache.get(for: type).hasEmptyDecoder {
            return cache
        }

        let result = try _hasEmptyDecoder(type: type)
        try cache.modify(for: type) { $0.hasEmptyDecoder = result }
        return result
    }

    private func _hasEmptyDecoder(type: SType) throws -> Bool {
        if let _ = typeMap.map(specifier: type.asSpecifier()) {
            /*
             mapped type doesn't have decoder
             */
            return true
        }

        let (wrapped, depth) = try unwrapOptional(type: type, limit: nil)
        if depth > 0 {
            return try hasEmptyDecoder(type: wrapped)
        }
        if let (_, type) = try asArray(type: type) {
            return try hasEmptyDecoder(type: type)
        }
        
        guard let type = type.regular else { return true }

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

    func decodeFunctionName(type: SType) -> String {
        var path = namePath(type: type)
        path.items.append("decode")
        return path.convert()
    }

    func generateDecodeFunctionAccess(type: SType) throws -> TSExpr {
        func makeClosure() throws -> TSExpr {
            let param = TSFunctionParameter(
                name: "json",
                type: try transpileTypeReference(type, kind: .json)
            )
            let ret = try transpileTypeReference(type, kind: .type)
            let expr = try generateValueDecodeExpression(
                type: type,
                expr: .identifier("json")
            )
            return .closure(TSClosureExpr(
                parameters: [param],
                returnType: ret,
                items: [.stmt(.return(expr))]
            ))
        }

        let (_, optionalDepth) = try unwrapOptional(type: type, limit: nil)
        if optionalDepth > 0 {
            return try makeClosure()
        }
        if let (_, _) = try asArray(type: type) {
            return try makeClosure()
        }
        return .identifier(decodeFunctionName(type: type))
    }

    var optionalFieldDecodeFunctionName: String {
        "OptionalField_decode"
    }

    var optionalDecodeFunctionName: String {
        "Optional_decode"
    }

    var arrayDecodeFunctionName: String {
        "Array_decode"
    }

    func generateFieldDecodeExpression(
        type: SType,
        expr: TSExpr
    ) throws -> TSExpr {
        let (type, optionalDepth) = try unwrapOptional(type: type, limit: 1)
        if optionalDepth > 0 {
            if try hasEmptyDecoder(type: type) { return expr }
            return try generateHigherOrderDecodeCall(
                type: type,
                callee: .identifier(optionalFieldDecodeFunctionName),
                json: expr
            )
        }

        return try generateValueDecodeExpression(
            type: type, expr: expr
        )
    }

    func generateValueDecodeExpression(
        type: SType,
        expr: TSExpr
    ) throws -> TSExpr {
        let (type, optionalDepth) = try unwrapOptional(type: type, limit: nil)
        if optionalDepth > 0 {
            if try hasEmptyDecoder(type: type) { return expr }
            return try generateHigherOrderDecodeCall(
                type: type,
                callee: .identifier(optionalDecodeFunctionName),
                json: expr
            )
        }

        if let (_, type) = try asArray(type: type) {
            if try hasEmptyDecoder(type: type) { return expr }
            return try generateHigherOrderDecodeCall(
                type: type,
                callee: .identifier(arrayDecodeFunctionName),
                json: expr
            )
        }

        if try hasEmptyDecoder(type: type) {
            return expr
        }

        let decode = decodeFunctionName(type: type)

        return .call(
            callee: .identifier(decode),
            arguments: [TSFunctionArgument(expr)]
        )
    }

    private func generateHigherOrderDecodeCall(
        type: SType,
        callee: TSExpr,
        json: TSExpr
    ) throws -> TSExpr {
        return .call(
            callee: callee,
            arguments: [
                TSFunctionArgument(json),
                TSFunctionArgument(
                    try generateDecodeFunctionAccess(type: type)
                )
            ]
        )
    }

    func unwrapOptional(type: SType, limit: Int?) throws -> (type: SType, depth: Int) {
        var type = type
        var depth = 0
        while isStandardLibraryType(type: type, name: "Optional") {
            if let limit = limit,
               depth >= limit
            {
                break
            }

            let args = try type.genericArguments()
            guard args.count == 1 else {
                throw MessageError("invalid generic arguments")
            }
            type = args[0]
            depth += 1
        }
        return (type: type, depth: depth)
    }

    func asArray(type: SType) throws -> (array: StructType, element: SType)? {
        guard isStandardLibraryType(type: type, name: "Array"),
              let array = type.struct,
              let element = try array.genericArguments()[safe: 0] else { return nil }
        return (array: array, element: element)
    }

    func isStandardLibraryType(type: SType, name: String) -> Bool {
        guard let type = type.regular else { return false }

        return type.location.elements == [.module(name: "Swift")] &&
        type.name == name
    }

    func associatedValueLabel(value: AssociatedValue, index: Int) -> String {
        if let name = value.name {
            return name
        } else {
            return "_\(index)"
        }
    }
}
