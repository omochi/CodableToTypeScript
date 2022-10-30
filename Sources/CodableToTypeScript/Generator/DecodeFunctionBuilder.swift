import SwiftTypeReader
import TSCodeModule

struct DecodeFunctionBuilder {
    init(converter: TypeConverter, type: SType) {
        self.c = converter
        self.h = c.helperLibrary()
        self.type = type
    }

    var c: TypeConverter
    var h: HelperLibraryGenerator
    var type: SType

    func name() -> String {
        var path = type.namePath()
        path.items.append("decode")
        return path.convert()
    }

    func signature() -> TSFunctionDecl {
        let typeName = c.transpiledName(of: type, kind: .type)
        let jsonName = c.transpiledName(of: type, kind: .json)

        let typeParameters: [GenericParameterType] = type.regular?.genericParameters ?? []

        var typeArgs: [TSGenericArgument] = []
        var jsonArgs: [TSGenericArgument] = []

        for param in typeParameters {
            typeArgs.append(TSGenericArgument(
                .named(param.name)
            ))
            jsonArgs.append(TSGenericArgument(
                .named(c.transpiledName(of: .genericParameter(param), kind: .json))
            ))
        }

        var genericParameters: [TSGenericParameter] = []
        for param in typeParameters {
            genericParameters.append(TSGenericParameter(.init(param.name)))
        }
        for param in typeParameters {
            let name = c.transpiledName(of: .genericParameter(param), kind: .json)
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
            let jsonName = c.transpiledName(of: .genericParameter(param), kind: .json)
            let decodeType: TSType = .function(
                parameters: [TSFunctionParameter(name: "json", type: .named(jsonName))],
                returnType: .named(param.name)
            )

            let decodeName = c.decodeFunction(type: .genericParameter(param)).name()

            parameters.append(TSFunctionParameter(
                name: decodeName,
                type: decodeType
            ))
        }

        return TSFunctionDecl(
            name: self.name(),
            genericParameters: genericParameters,
            parameters: parameters,
            returnType: returnType,
            items: []
        )
    }

    func access() throws -> TSExpr {
        func makeClosure() throws -> TSExpr {
            let param = TSFunctionParameter(
                name: "json",
                type: try c.transpileTypeReference(type, kind: .json)
            )
            let ret = try c.transpileTypeReference(type, kind: .type)
            let expr = try decodeValue(type: type, expr: .identifier("json"))
            return .closure(TSClosureExpr(
                parameters: [param],
                returnType: ret,
                items: [.stmt(.return(expr))]
            ))
        }

        if try c.hasEmptyDecoder(type: type) {
            return h.access(.identityFunction)
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
        return .identifier(self.name())
    }

    func decodeField(
        type: SType,
        expr: TSExpr
    ) throws -> TSExpr {
        if let (wrapped, _) = try type.unwrapOptional(limit: 1) {
            if try c.hasEmptyDecoder(type: wrapped) { return expr }
            return try callHeigherOrderDecode(
                types: [wrapped],
                callee: h.access(.optionalFieldDecodeFunction),
                json: expr
            )
        }

        return try decodeValue(type: type, expr: expr)
    }

    func decodeValue(
        type: SType,
        expr: TSExpr
    ) throws -> TSExpr {
        if let (wrapped, _) = try type.unwrapOptional(limit: nil) {
            if try c.hasEmptyDecoder(type: wrapped) { return expr }
            return try callHeigherOrderDecode(
                types: [wrapped],
                callee: h.access(.optionalDecodeFunction),
                json: expr
            )
        }
        if let (_, element) = try type.asArray() {
            if try c.hasEmptyDecoder(type: element) { return expr }
            return try callHeigherOrderDecode(
                types: [element],
                callee: h.access(.arrayDecodeFunction),
                json: expr
            )
        }
        if let (_, value) = try type.asDictionary() {
            if try c.hasEmptyDecoder(type: value) { return expr }
            return try callHeigherOrderDecode(
                types: [value],
                callee: h.access(.dictionaryDecodeFunction),
                json: expr
            )
        }

        if try c.hasEmptyDecoder(type: type) {
            return expr
        }

        let decode: TSExpr = .identifier(c.decodeFunction(type: type).name())

        let typeArgs = try type.genericArguments()
        if typeArgs.count > 0 {
            return try callHeigherOrderDecode(
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

    private func callHeigherOrderDecode(
        types: [SType],
        callee: TSExpr,
        json: TSExpr
    ) throws -> TSExpr {
        var args: [TSFunctionArgument] = [
            TSFunctionArgument(json)
        ]

        for type in types {
            let decode = try c.decodeFunction(type: type).access()
            args.append(TSFunctionArgument(decode))
        }

        return .call(callee: callee, arguments: args)
    }
}
