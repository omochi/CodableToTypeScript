import SwiftTypeReader
import TypeScriptAST

/*
 It provides default impls of TypeConverter.
 */
public struct DefaultTypeConverter {
    public init(generator: CodeGenerator, type: any SType) {
        self.generator = generator
        self.type = type
    }

    private var generator: CodeGenerator
    public var type: any SType

    private func converter() throws -> any TypeConverter {
        return try generator.converter(for: type)
    }

    public func name(for target: GenerationTarget) throws -> String {
        switch target {
        case .entity:
            return type.namePath().convert()
        case .json:
            let converter = try self.converter()

            let entityName = try converter.name(for: .entity)

            guard try converter.hasJSONType() else {
                return entityName
            }

            return Self.jsonName(entityName: entityName)
        }
    }

    public static func jsonName(entityName: String) -> String {
        return "\(entityName)_JSON"
    }

    public func hasJSONType() throws -> Bool {
        let converter = try self.converter()
        if try converter.hasDecode() {
            return true
        }
        return false
    }

    public func type(for target: GenerationTarget) throws -> any TSType {
        let converter = try self.converter()
        let name = try converter.name(for: target)
        let args = try converter.genericArgs().map {
            try $0.type(for: target)
        }
        return TSIdentType(name, genericArgs: args)
    }

    public func fieldType(for target: GenerationTarget) throws -> (type: any TSType, isOptional: Bool) {
        let type = try self.converter().type(for: target)
        return (type: type, isOptional: false)
    }

    public func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        switch target {
        case .entity: break
        case .json:
            guard try self.converter().hasJSONType() else { return nil }
        }
        throw MessageError("Unsupported type: \(type)")
    }

    public func decodeName() throws -> String {
        let converter = try self.converter()
        guard try converter.hasDecode() else {
            throw MessageError("no decoder")
        }
        let entityName = try converter.name(for: .entity)
        return Self.decodeName(entityName: entityName)
    }

    public static func decodeName(entityName: String) -> String {
        return "\(entityName)_decode"
    }

    public func boundDecode() throws -> any TSExpr {
        let converter = try self.converter()

        guard try converter.hasDecode() else {
            return generator.helperLibrary().access(.identityFunction)
        }

        func makeClosure() throws -> any TSExpr {
            let param = TSFunctionType.Param(
                name: "json",
                type: try converter.type(for: .json)
            )
            let result = try converter.type(for: .entity)
            let expr = try converter.callDecode(json: TSIdentExpr("json"))
            return TSClosureExpr(
                params: [param],
                result: result,
                body: TSBlockStmt([
                    TSReturnStmt(expr)
                ])
            )
        }

        if !type.genericArgs.isEmpty {
            return try makeClosure()
        }
        return TSIdentExpr(
            try converter.decodeName()
        )
    }

    public func callDecode(json: any TSExpr) throws -> any TSExpr {
        let converter = try self.converter()
        guard try converter.hasDecode() else {
            return json
        }
        let decodeName = try converter.decodeName()
        return try generator.callDecode(
            callee: TSIdentExpr(decodeName),
            genericArgs: type.genericArgs,
            json: json
        )
    }

    public func callDecodeField(json: any TSExpr) throws -> any TSExpr {
        return try converter().callDecode(json: json)
    }

    public func decodeSignature() throws -> TSFunctionDecl? {
        let converter = try self.converter()

        guard try converter.hasDecode() else { return nil }

        let entityName = try converter.name(for: .entity)
        let jsonName = try converter.name(for: .json)

        let genericParams = try converter.genericParams()

        var entityArgs: [any TSType] = []
        var jsonArgs: [any TSType] = []

        for param in genericParams {
            entityArgs.append(
                TSIdentType(try param.name(for: .entity))
            )
            jsonArgs.append(
                TSIdentType(try param.name(for: .json))
            )
        }

        var decodeGenericParams: [String] = []
        for param in genericParams {
            decodeGenericParams.append(try param.name(for: .entity))
        }
        for param in genericParams {
            decodeGenericParams.append(try param.name(for: .json))
        }

        var parameters: [TSFunctionType.Param] = [
            .init(
                name: "json",
                type: TSIdentType(jsonName, genericArgs: jsonArgs)
            )
        ]
        let result: any TSType = TSIdentType(entityName, genericArgs: entityArgs)

        for param in genericParams {
            let jsonName = try param.name(for: .json)
            let decodeType: any TSType = TSFunctionType(
                params: [.init(name: "json", type: TSIdentType(jsonName))],
                result: TSIdentType(try param.name(for: .entity))
            )

            let decodeName = try param.decodeName()

            parameters.append(
                .init(
                    name: decodeName,
                    type: decodeType
                )
            )
        }

        return TSFunctionDecl(
            modifiers: [.export],
            name: try decodeName(),
            genericParams: decodeGenericParams,
            params: parameters,
            result: result,
            body: TSBlockStmt()
        )
    }

    public func decodeDecl() throws -> TSFunctionDecl? {
        guard let _ = try decodeSignature() else { return nil }
        throw MessageError("Unsupported type: \(type)")
    }
}
