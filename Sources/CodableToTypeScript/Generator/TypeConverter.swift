import SwiftTypeReader
import TSCodeModule

final class TypeConverter {
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
        if let (wrapped, _) = try type.unwrapOptional(limit: nil) {
            return .union([
                try transpileTypeReference(wrapped, kind: kind),
                .named("null")
            ])
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
        if let (_, _) = try type.unwrapOptional(limit: nil) {
            return try makeClosure()
        }
        if let (_, _) = try type.asArray() {
            return try makeClosure()
        }
        if let (_, _) = try type.asDictionary() {
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
        if let (wrapped, _) = try type.unwrapOptional(limit: 1) {
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
        if let (wrapped, _) = try type.unwrapOptional(limit: nil) {
            if try hasEmptyDecoder(type: wrapped) { return expr }
            return try generateHigherOrderDecodeCall(
                types: [wrapped],
                callee: .identifier(optionalDecodeFunctionName),
                json: expr
            )
        }
        if let (_, element) = try type.asArray() {
            if try hasEmptyDecoder(type: element) { return expr }
            return try generateHigherOrderDecodeCall(
                types: [element],
                callee: .identifier(arrayDecodeFunctionName),
                json: expr
            )
        }
        if let (_, value) = try type.asDictionary() {
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
}
