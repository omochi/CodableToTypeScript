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
                .enum,
                .genericParameter:
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
        if let (wrapped, _) = try unwrapOptional(type: type, limit: nil) {
            return .union([
                try transpileTypeReference(wrapped, kind: kind),
                .named("null")
            ])
        }
        if let (_, element) = try asArray(type: type) {
            return .array(
                try transpileTypeReference(element, kind: kind)
            )
        }
        if let (_, value) = try asDictionary(type: type) {
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

    func transpileFieldTypeReference(type: SType, kind: TypeKind) throws -> (type: TSType, isOptionalField: Bool) {
        var type = type
        var isOptionalField = false
        if let (wrapped, _) = try unwrapOptional(type: type, limit: 1) {
            type = wrapped
            isOptionalField = true
        }
        return (
            type: try transpileTypeReference(type, kind: kind),
            isOptionalField: isOptionalField
        )
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

        if let (wrapped, _) = try unwrapOptional(type: type, limit: nil) {
            return try hasEmptyDecoder(type: wrapped)
        }
        if let (_, element) = try asArray(type: type) {
            return try hasEmptyDecoder(type: element)
        }
        if let (_, value) = try asDictionary(type: type) {
            return try hasEmptyDecoder(type: value)
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
        case .genericParameter:
            return false
        case .protocol:
            return true
        }
    }

    func decodeFunctionName(type: SType) -> String {
        if let type = type.genericParameter {
            let param = transpileGenericParameter(type: .genericParameter(type), kind: .type)
            return genericParameterDecodeFunctionName(type: param.type)
        }

        var path = namePath(type: type)
        path.items.append("decode")
        return path.convert()
    }

    private func genericParameterDecodeFunctionName(type: TSNamedType) -> String {
        return type.name + "_decode"
    }

    func decodeFunctionSignature(type: SType) -> TSFunctionDecl {
        let typeName = transpiledName(of: type, kind: .type)
        let jsonName = transpiledName(of: type, kind: .json)
        let funcName = decodeFunctionName(type: type)

        let typeParameters: [GenericParameterType] = type.regular?.genericParameters ?? []

        var typeArgs: [TSGenericArgument] = []
        var jsonArgs: [TSGenericArgument] = []

        for param in typeParameters {
            typeArgs.append(TSGenericArgument(
                .named(param.name)
            ))
            jsonArgs.append(TSGenericArgument(
                .named(transpiledName(of: .genericParameter(param), kind: .json))
            ))
        }

        var genericParameters: [TSGenericParameter] = []
        for param in typeParameters {
            genericParameters.append(TSGenericParameter(.init(param.name)))
        }
        for param in typeParameters {
            let name = transpiledName(of: .genericParameter(param), kind: .json)
            genericParameters.append(TSGenericParameter(.init(name)))
        }

        var parameters: [TSFunctionParameter] = [
            TSFunctionParameter(
                name: "json",
                type: .named(jsonName, genericArguments: jsonArgs)
            )
        ]
        let returnType: TSType = .named(typeName, genericArguments: typeArgs)

        for param in typeParameters {
            let jsonName = transpiledName(of: .genericParameter(param), kind: .json)
            let decodeType: TSType = .function(
                parameters: [TSFunctionParameter(name: "json", type: .named(jsonName))],
                returnType: .named(param.name)
            )

            let decodeName = genericParameterDecodeFunctionName(type: .init(param.name))

            parameters.append(TSFunctionParameter(
                name: decodeName,
                type: decodeType
            ))
        }

        return TSFunctionDecl(
            name: funcName,
            genericParameters: genericParameters,
            parameters: parameters,
            returnType: returnType,
            items: []
        )
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

        if try hasEmptyDecoder(type: type) {
            return .identifier(identityFunctionName)
        }
        if let (_, _) = try unwrapOptional(type: type, limit: nil) {
            return try makeClosure()
        }
        if let (_, _) = try asArray(type: type) {
            return try makeClosure()
        }
        if let (_, _) = try asDictionary(type: type) {
            return try makeClosure()
        }
        return .identifier(decodeFunctionName(type: type))
    }

    let optionalFieldDecodeFunctionName = "OptionalField_decode"
    let optionalDecodeFunctionName = "Optional_decode"
    let arrayDecodeFunctionName = "Array_decode"
    let dictionaryDecodeFunctionName = "Dictionary_decode"
    let identityFunctionName = "identity"

    func generateFieldDecodeExpression(
        type: SType,
        expr: TSExpr
    ) throws -> TSExpr {
        if let (wrapped, _) = try unwrapOptional(type: type, limit: 1) {
            if try hasEmptyDecoder(type: wrapped) { return expr }
            return try generateHigherOrderDecodeCall(
                types: [wrapped],
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
        if let (wrapped, _) = try unwrapOptional(type: type, limit: nil) {
            if try hasEmptyDecoder(type: wrapped) { return expr }
            return try generateHigherOrderDecodeCall(
                types: [wrapped],
                callee: .identifier(optionalDecodeFunctionName),
                json: expr
            )
        }
        if let (_, element) = try asArray(type: type) {
            if try hasEmptyDecoder(type: element) { return expr }
            return try generateHigherOrderDecodeCall(
                types: [element],
                callee: .identifier(arrayDecodeFunctionName),
                json: expr
            )
        }
        if let (_, value) = try asDictionary(type: type) {
            if try hasEmptyDecoder(type: value) { return expr }
            return try generateHigherOrderDecodeCall(
                types: [value],
                callee: .identifier(dictionaryDecodeFunctionName),
                json: expr
            )
        }

        if try hasEmptyDecoder(type: type) {
            return expr
        }

        let decode: TSExpr = .identifier(decodeFunctionName(type: type))

        let typeArgs = try type.genericArguments()
        if typeArgs.count > 0 {
            return try generateHigherOrderDecodeCall(
                types: typeArgs,
                callee: decode,
                json: expr
            )
        }

        return .call(
            callee: decode,
            arguments: [TSFunctionArgument(expr)]
        )
    }

    private func generateHigherOrderDecodeCall(
        types: [SType],
        callee: TSExpr,
        json: TSExpr
    ) throws -> TSExpr {
        var args: [TSFunctionArgument] = [
            TSFunctionArgument(json)
        ]

        for type in types {
            let decode = try generateDecodeFunctionAccess(type: type)
            args.append(TSFunctionArgument(decode))
        }

        return .call(callee: callee, arguments: args)
    }

    func unwrapOptional(type: SType, limit: Int?) throws -> (wrapped: SType, depth: Int)? {
        var type = type
        var depth = 0
        while isStandardLibraryType(type: type, name: "Optional"),
              let optional = type.struct,
              let wrapped = try optional.genericArguments()[safe: 0]
        {
            if let limit = limit,
               depth >= limit
            {
                break
            }

            type = wrapped
            depth += 1
        }

        if depth == 0 { return nil }
        return (wrapped: type, depth: depth)
    }

    func asArray(type: SType) throws -> (array: StructType, element: SType)? {
        guard isStandardLibraryType(type: type, name: "Array"),
              let array = type.struct,
              let element = try array.genericArguments()[safe: 0] else { return nil }
        return (array: array, element: element)
    }

    func asDictionary(type: SType) throws -> (dictionary: StructType, value: SType)? {
        guard isStandardLibraryType(type: type, name: "Dictionary"),
              let dict = type.struct,
              let value = try dict.genericArguments()[safe: 1] else { return nil }
        return (dictionary: dict, value: value)
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
