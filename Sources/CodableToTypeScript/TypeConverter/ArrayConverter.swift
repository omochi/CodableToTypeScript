import SwiftTypeReader
import TypeScriptAST

public struct ArrayConverter: TypeConverter {
    public init(generator: CodeGenerator, swiftType: any SType) {
        self.generator = generator
        self.swiftType = swiftType
    }

    public var generator: CodeGenerator
    public var swiftType: any SType

    private func element() throws -> any TypeConverter {
        let (_, element) = swiftType.asArray()!
        return try generator.converter(for: element)
    }

    public func type(for target: GenerationTarget) throws -> any TSType {
        return TSArrayType(
            try element().type(for: target)
        )
    }

    public func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        throw MessageError("Unsupported type: \(swiftType)")
    }

    public func hasDecode() throws -> Bool {
        return try element().hasDecode()
    }

    public func decodePresence() throws -> CodecPresence {
        return try element().decodePresence()
    }

    public func decodeName() throws -> String? {
        return generator.helperLibrary().name(.arrayDecode)
    }

    public func callDecode(json: any TSExpr) throws -> any TSExpr {
        return try `default`.callDecode(
            genericArgs: [try element().swiftType],
            json: json
        )
    }

    public func decodeDecl() throws -> TSFunctionDecl? {
        throw MessageError("Unsupported type: \(swiftType)")
    }

    public func hasEncode() throws -> Bool {
        return try element().hasEncode()
    }

    public func encodePresence() throws -> CodecPresence {
        return try element().encodePresence()
    }

    public func encodeName() throws -> String {
        return generator.helperLibrary().name(.arrayEncode)
    }

    public func callEncode(entity: any TSExpr) throws -> any TSExpr {
        return try `default`.callEncode(
            genericArgs: [try element().swiftType],
            entity: entity
        )
    }

    public func encodeDecl() throws -> TSFunctionDecl? {
        throw MessageError("Unsupported type: \(swiftType)")
    }
}
