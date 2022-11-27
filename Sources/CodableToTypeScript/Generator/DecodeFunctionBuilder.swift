import SwiftTypeReader
import TypeScriptAST

struct DecodeFunctionBuilder {
    init(generator: CodeGenerator) {
        self.gen = generator
    }

    var gen: CodeGenerator

    func name(type: any SType) -> String {
        let base = type.namePath().convert()
        return self.name(base: base)
    }

    func name(base: String) -> String {
        return "\(base)_decode"
    }

    func signature(type: any TypeDecl) throws -> TSFunctionDecl {
        let typeName = try gen.transpileTypeName(type: type, target: .entity)
        let jsonName = try gen.transpileTypeName(type: type, target: .json)

        let typeParameters: [GenericParamDecl] = type.genericParams.items

        var typeArgs: [any TSType] = []
        var jsonArgs: [any TSType] = []

        for param in typeParameters {
            typeArgs.append(
                TSIdentType(param.name)
            )
            jsonArgs.append(
                TSIdentType(try gen.transpileTypeName(type: param, target: .json))
            )
        }

        var genericParameters: [String] = []
        for param in typeParameters {
            genericParameters.append(param.name)
        }
        for param in typeParameters {
            let name = try gen.transpileTypeName(type: param, target: .json)
            genericParameters.append(name)
        }

        var parameters: [TSFunctionType.Param] = [
            .init(
                name: "json",
                type: TSIdentType(jsonName, genericArgs: jsonArgs)
            )
        ]
        let result: any TSType = TSIdentType(typeName, genericArgs: typeArgs)

        for param in typeParameters {
            let jsonName = try gen.transpileTypeName(type: param, target: .json)
            let decodeType: any TSType = TSFunctionType(
                params: [.init(name: "json", type: TSIdentType(jsonName))],
                result: TSIdentType(param.name)
            )

            let decodeName = self.name(type: param.declaredInterfaceType)

            parameters.append(
                .init(
                    name: decodeName,
                    type: decodeType
                )
            )
        }

        return TSFunctionDecl(
            modifiers: [.export],
            name: self.name(type: type.declaredInterfaceType),
            genericParams: genericParameters,
            params: parameters,
            result: result,
            body: TSBlockStmt()
        )
    }

    func access(type: any SType) throws -> any TSExpr {
        func makeClosure() throws -> any TSExpr {
            let param = TSFunctionType.Param(
                name: "json",
                type: try gen.transpileTypeReference(type, target: .json)
            )
            let ret = try gen.transpileTypeReference(type, target: .entity)
            let expr = try decodeValue(type: type, expr: TSIdentExpr("json"))
            return TSClosureExpr(
                params: [param],
                result: ret,
                body: TSBlockStmt([
                    TSReturnStmt(expr)
                ])
            )
        }

        guard try gen.hasJSONType(type: type) else {
            return gen.helperLibrary().access(.identityFunction)
        }

        if !type.genericArgs.isEmpty {
            return try makeClosure()
        }
        return TSIdentExpr(self.name(type: type))
    }

    func decodeField(type: any SType, expr: any TSExpr) throws -> any TSExpr {
        if let (wrapped, _) = type.unwrapOptional(limit: 1) {
            guard try gen.hasJSONType(type: wrapped) else { return expr }
            return try callHeigherOrderDecode(
                types: [wrapped],
                callee: gen.helperLibrary().access(.optionalFieldDecodeFunction),
                json: expr
            )
        }

        return try decodeValue(type: type, expr: expr)
    }

    func decodeValue(type: any SType, expr: any TSExpr) throws -> any TSExpr {
        let lib = gen.helperLibrary()
        if let (wrapped, _) = type.unwrapOptional(limit: nil) {
            guard try gen.hasJSONType(type: wrapped) else { return expr }
            return try callHeigherOrderDecode(
                types: [wrapped],
                callee: lib.access(.optionalDecodeFunction),
                json: expr
            )
        }
        if let (_, element) = type.asArray() {
            guard try gen.hasJSONType(type: element) else { return expr }
            return try callHeigherOrderDecode(
                types: [element],
                callee: lib.access(.arrayDecodeFunction),
                json: expr
            )
        }
        if let (_, value) = type.asDictionary() {
            guard try gen.hasJSONType(type: value) else { return expr }
            return try callHeigherOrderDecode(
                types: [value],
                callee: lib.access(.dictionaryDecodeFunction),
                json: expr
            )
        }

        guard try gen.hasJSONType(type: type) else {
            return expr
        }

        let decode: any TSExpr = TSIdentExpr(self.name(type: type))

        let typeArgs = type.genericArgs
        if typeArgs.count > 0 {
            return try callHeigherOrderDecode(
                types: typeArgs,
                callee: decode,
                json: expr
            )
        }

        return TSCallExpr(
            callee: decode,
            args: [expr]
        )
    }

    private func callHeigherOrderDecode(types: [any SType], callee: any TSExpr, json: any TSExpr) throws -> any TSExpr {
        var args: [any TSExpr] = [json]

        for type in types {
            let decode = try self.access(type: type)
            args.append(decode)
        }

        return TSCallExpr(callee: callee, args: args)
    }

}
