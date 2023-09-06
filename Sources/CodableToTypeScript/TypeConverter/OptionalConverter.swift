import SwiftTypeReader
import TypeScriptAST

public struct OptionalConverter: TypeConverter {
    public init(generator: CodeGenerator, swiftType: any SType) {
        self.generator = generator
        self.swiftType = swiftType
    }
    
    public var generator: CodeGenerator
    public var swiftType: any SType

    private func wrapped(limit: Int?) throws -> any TypeConverter {
        let (wrapped, _) = swiftType.unwrapOptional(limit: limit)!
        return try generator.converter(for: wrapped)
    }

    public func type(for target: GenerationTarget) throws -> any TSType {
        return TSUnionType(
            try wrapped(limit: nil).type(for: target),
            TSIdentType.null
        )
    }

    public func fieldType(for target: GenerationTarget) throws -> (type: any TSType, isOptional: Bool) {
        return (
            type: try wrapped(limit: 1).type(for: target),
            isOptional: true
        )
    }

    public func valueToField(value: any TSExpr, for target: GenerationTarget) throws -> any TSExpr {
        return TSInfixOperatorExpr(value, "??", TSIdentExpr.undefined)
    }

    public func fieldToValue(field: any TSExpr, for target: GenerationTarget) throws -> any TSExpr {
        return TSInfixOperatorExpr(field, "??", TSNullLiteralExpr())
    }

    public func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        throw MessageError("Unsupported type: \(swiftType)")
    }

    public func decodePresence() throws -> CodecPresence {
        return try wrapped(limit: nil).decodePresence()
    }

    public func decodeName() throws -> String? {
        return generator.helperLibrary().name(.optionalDecode)
    }

    public func callDecode(json: any TSExpr) throws -> any TSExpr {
        return try `default`.callDecode(
            genericArgs: [try wrapped(limit: nil).swiftType],
            json: json
        )
    }

    public func callDecodeField(json: any TSExpr) throws -> any TSExpr {
        guard try hasDecode() else { return json }
        let decodeName = generator.helperLibrary().name(.optionalFieldDecode)
        return try generator.callDecode(
            callee: TSIdentExpr(decodeName),
            genericArgs: [try wrapped(limit: 1).swiftType],
            json: json
        )
    }

    public func decodeDecl() throws -> TSFunctionDecl? {
        throw MessageError("Unsupported type: \(swiftType)")
    }

    public func encodePresence() throws -> CodecPresence {
        return try wrapped(limit: nil).encodePresence()
    }

    public func encodeName() throws -> String {
        return generator.helperLibrary().name(.optionalEncode)
    }

    public func callEncode(entity: any TSExpr) throws -> any TSExpr {
        return try `default`.callEncode(
            genericArgs: [try wrapped(limit: nil).swiftType],
            entity: entity
        )
    }

    public func callEncodeField(entity: any TSExpr) throws -> any TSExpr {
        guard try hasEncode() else { return entity }
        let encodeName = generator.helperLibrary().name(.optionalFieldEncode)
        return try generator.callEncode(
            callee: TSIdentExpr(encodeName),
            genericArgs: [try wrapped(limit: 1).swiftType],
            entity: entity
        )
    }

    public func encodeDecl() throws -> TSFunctionDecl? {
        throw MessageError("Unsupported type: \(swiftType)")
    }
}
