import SwiftTypeReader
import TSCodeModule

struct DecodeFunctionBuilder {
    init(converter: TypeConverter) {
        self.c = converter
    }

    var c: TypeConverter

    func name(type: any SType) -> String {
        let base = type.namePath().convert()
        return self.name(base: base)
    }

    func name(base: String) -> String {
        return "\(base)_decode"
    }

    func signature(type: any TypeDecl) -> TSFunctionDecl {
        let typeName = c.transpiledName(of: type, kind: .type)
        let jsonName = c.transpiledName(of: type, kind: .json)

        let typeParameters: [GenericParamDecl] = type.genericParams.items

        var typeArgs: [TSGenericArgument] = []
        var jsonArgs: [TSGenericArgument] = []

        for param in typeParameters {
            typeArgs.append(TSGenericArgument(
                .named(param.name)
            ))
            jsonArgs.append(TSGenericArgument(
                .named(c.transpiledName(of: param, kind: .json))
            ))
        }

        var genericParameters: [TSGenericParameter] = []
        for param in typeParameters {
            genericParameters.append(TSGenericParameter(.init(param.name)))
        }
        for param in typeParameters {
            let name = c.transpiledName(of: param, kind: .json)
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
            let jsonName = c.transpiledName(of: param, kind: .json)
            let decodeType: TSType = .function(
                parameters: [.init(name: "json", type: .named(jsonName))],
                returnType: .named(param.name)
            )

            let decodeName = self.name(type: param.declaredInterfaceType)

            parameters.append(TSFunctionParameter(
                name: decodeName,
                type: decodeType
            ))
        }

        return TSFunctionDecl(
            name: self.name(type: type.declaredInterfaceType),
            genericParameters: genericParameters,
            parameters: parameters,
            returnType: returnType,
            items: []
        )
    }

    func access(type: any SType) throws -> TSExpr {
        func makeClosure() throws -> TSExpr {
            let param = TSFunctionParameter(
                name: "json",
                type: try c.transpileTypeReference(type, kind: .json)
            )
            let ret = try c.transpileTypeReference(type, kind: .type)
            let expr = try decodeValue(type: type, expr: .identifier("json"))
            return .closure(
                parameters: [param],
                returnType: ret,
                body: .block([
                    .stmt(.return(expr))
                ])
            )
        }

        if try c.hasEmptyDecoder(type: type) {
            return c.helperLibrary().access(.identityFunction)
        }

        if !type.genericArgs.isEmpty {
            return try makeClosure()
        }
        return .identifier(self.name(type: type))
    }

    func decodeField(type: any SType, expr: TSExpr) throws -> TSExpr {
        if let (wrapped, _) = type.unwrapOptional(limit: 1) {
            if try c.hasEmptyDecoder(type: wrapped) { return expr }
            return try callHeigherOrderDecode(
                types: [wrapped],
                callee: c.helperLibrary().access(.optionalFieldDecodeFunction),
                json: expr
            )
        }

        return try decodeValue(type: type, expr: expr)
    }

    func decodeValue(type: any SType, expr: TSExpr) throws -> TSExpr {
        let lib = c.helperLibrary()
        if let (wrapped, _) = type.unwrapOptional(limit: nil) {
            if try c.hasEmptyDecoder(type: wrapped) { return expr }
            return try callHeigherOrderDecode(
                types: [wrapped],
                callee: lib.access(.optionalDecodeFunction),
                json: expr
            )
        }
        if let (_, element) = type.asArray() {
            if try c.hasEmptyDecoder(type: element) { return expr }
            return try callHeigherOrderDecode(
                types: [element],
                callee: lib.access(.arrayDecodeFunction),
                json: expr
            )
        }
        if let (_, value) = type.asDictionary() {
            if try c.hasEmptyDecoder(type: value) { return expr }
            return try callHeigherOrderDecode(
                types: [value],
                callee: lib.access(.dictionaryDecodeFunction),
                json: expr
            )
        }

        if try c.hasEmptyDecoder(type: type) {
            return expr
        }

        let decode: TSExpr = .identifier(self.name(type: type))

        let typeArgs = type.genericArgs
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

    private func callHeigherOrderDecode(types: [any SType], callee: TSExpr, json: TSExpr) throws -> TSExpr {
        var args: [TSFunctionArgument] = [
            TSFunctionArgument(json)
        ]

        for type in types {
            let decode = try self.access(type: type)
            args.append(TSFunctionArgument(decode))
        }

        return .call(callee: callee, arguments: args)
    }

}
