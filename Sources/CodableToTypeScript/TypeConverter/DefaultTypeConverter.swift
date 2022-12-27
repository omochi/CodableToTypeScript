import SwiftTypeReader
import TypeScriptAST

/*
 It provides default impls of TypeConverter.

 Don't call other method from own methods.
 Call original methods via `converter()` object.
 */
public struct DefaultTypeConverter {
    public init(generator: CodeGenerator, type: any SType) {
        self.generator = generator
        self.swiftType = type
    }

    private var generator: CodeGenerator
    public var swiftType: any SType

    private func converter() throws -> any TypeConverter {
        return try generator.converter(for: swiftType)
    }

    public func name(for target: GenerationTarget) throws -> String {
        switch target {
        case .entity:
            return swiftType.namePath().convert()
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
        if try converter.hasEncode() {
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

    public func valueToField(value: any TSExpr, for target: GenerationTarget) throws -> any TSExpr {
        return value
    }

    public func fieldToValue(field: any TSExpr, for target: GenerationTarget) throws -> any TSExpr {
        return field
    }

    public func hasDecode() throws -> Bool {
        switch try self.converter().decodePresence() {
        case .identity: return false
        case .required: return true
        case .conditional:
            let args = try swiftType.genericArgs.map {
                try self.generator.converter(for: $0)
            }
            return try args.contains { try $0.hasDecode() }
        }
    }

    public func decodeName() throws -> String {
        let converter = try self.converter()
        guard try converter.hasDecode() else {
            throw MessageError("no decode")
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
            return generator.helperLibrary().access(.identity)
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

        if !swiftType.genericArgs.isEmpty {
            return try makeClosure()
        }
        return TSIdentExpr(
            try converter.decodeName()
        )
    }

    public func callDecode(json: any TSExpr) throws -> any TSExpr {
        return try callDecode(genericArgs: swiftType.genericArgs, json: json)
    }

    public func callDecode(genericArgs: [any SType], json: any TSExpr) throws -> any TSExpr {
        let converter = try self.converter()
        guard try converter.hasDecode() else {
            var expr = json
            if try converter.hasJSONType() {
                expr = TSAsExpr(expr, try converter.type(for: .entity))
            }
            return expr
        }
        let decodeName = try converter.decodeName()
        return try generator.callDecode(
            callee: TSIdentExpr(decodeName),
            genericArgs: genericArgs,
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

        var decodeGenericParams: [TSTypeParameterNode] = []
        for param in genericParams {
            decodeGenericParams.append(
                .init(try param.name(for: .entity))
            )
        }
        for param in genericParams {
            decodeGenericParams.append(
                .init(try param.name(for: .json))
            )
        }

        var params: [TSFunctionType.Param] = [
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

            params.append(
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
            params: params,
            result: result,
            body: TSBlockStmt()
        )
    }

    public func hasEncode() throws -> Bool {
        switch try self.converter().encodePresence() {
        case .identity: return false
        case .required: return true
        case .conditional:
            let args = try swiftType.genericArgs.map {
                try self.generator.converter(for: $0)
            }
            return try args.contains { try $0.hasEncode() }
        }
    }

    public func encodeName() throws -> String {
        let converter = try self.converter()
        guard try converter.hasEncode() else {
            throw MessageError("no encode")
        }
        let entityName = try converter.name(for: .entity)
        return Self.encodeName(entityName: entityName)
    }

    public static func encodeName(entityName: String) -> String {
        return "\(entityName)_encode"
    }

    public func boundEncode() throws -> any TSExpr {
        let converter = try self.converter()

        guard try converter.hasEncode() else {
            return generator.helperLibrary().access(.identity)
        }

        func makeClosure() throws -> any TSExpr {
            let param = TSFunctionType.Param(
                name: "entity",
                type: try converter.type(for: .entity)
            )
            let result = try converter.type(for: .json)
            let expr = try converter.callEncode(entity: TSIdentExpr("entity"))
            return TSClosureExpr(
                params: [param],
                result: result,
                body: TSBlockStmt([
                    TSReturnStmt(expr)
                ])
            )
        }

        if !swiftType.genericArgs.isEmpty {
            return try makeClosure()
        }
        return TSIdentExpr(
            try converter.encodeName()
        )
    }

    public func callEncode(entity: any TSExpr) throws -> any TSExpr {
        return try callEncode(genericArgs: swiftType.genericArgs, entity: entity)
    }

    public func callEncode(genericArgs: [any SType], entity: any TSExpr) throws -> any TSExpr {
        let converter = try self.converter()
        guard try converter.hasEncode() else {
            var expr = entity
            if try converter.hasJSONType() {
                expr = TSAsExpr(expr, try converter.type(for: .json))
            }
            return expr
        }
        let encodeName = try converter.encodeName()
        return try generator.callEncode(
            callee: TSIdentExpr(encodeName),
            genericArgs: genericArgs,
            entity: entity
        )
    }

    public func callEncodeField(entity: any TSExpr) throws -> any TSExpr {
        return try converter().callEncode(entity: entity)
    }

    public func encodeSignature() throws -> TSFunctionDecl? {
        let converter = try self.converter()

        guard try converter.hasEncode() else { return nil }

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

        var encodeGenericParams: [TSTypeParameterNode] = []
        for param in genericParams {
            encodeGenericParams.append(
                .init(try param.name(for: .entity))
            )
        }
        for param in genericParams {
            encodeGenericParams.append(
                .init(try param.name(for: .json))
            )
        }

        var params: [TSFunctionType.Param] = [
            .init(
                name: "entity",
                type: TSIdentType(entityName, genericArgs: entityArgs)
            )
        ]
        let result: any TSType = TSIdentType(jsonName, genericArgs: jsonArgs)

        for param in genericParams {
            let entityName = try param.name(for: .entity)
            let encodeType: any TSType = TSFunctionType(
                params: [.init(name: "entity", type: TSIdentType(entityName))],
                result: TSIdentType(try param.name(for: .json))
            )

            let encodeName = try param.encodeName()

            params.append(
                .init(
                    name: encodeName,
                    type: encodeType
                )
            )
        }

        return TSFunctionDecl(
            modifiers: [.export],
            name: try encodeName(),
            genericParams: encodeGenericParams,
            params: params,
            result: result,
            body: TSBlockStmt()
        )
    }
}
