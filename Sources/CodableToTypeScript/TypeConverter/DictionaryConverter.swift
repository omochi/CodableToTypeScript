import SwiftTypeReader
import TypeScriptAST

public struct DictionaryConverter: TypeConverter {
    public init(generator: CodeGenerator, swiftType: any SType) {
        self.generator = generator
        self.swiftType = swiftType
    }
    
    public var generator: CodeGenerator
    public var swiftType: any SType

    private func value() throws -> any TypeConverter {
        let (_, value) = swiftType.asDictionary()!
        return try generator.converter(for: value)
    }

    public func type(for target: GenerationTarget) throws -> any TSType {
        let value = try self.value().type(for: target)
        switch target {
        case .entity:
            return TSIdentType.map(TSIdentType.string, value)
        case .json:
            return TSObjectType.dictionary(value)
        }
    }

    public func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        throw MessageError("Unsupported type: \(swiftType)")
    }

    public func hasDecode() throws -> Bool {
        return true
    }

    public func decodeName() throws -> String? {
        return generator.helperLibrary().name(.dictionaryDecode)
    }

    public func callDecode(json: any TSExpr) throws -> any TSExpr {
        return try `default`.callDecode(
            genericArgs: [try value().swiftType],
            json: json
        )
    }

    public func decodeDecl() throws -> TSFunctionDecl? {
        throw MessageError("Unsupported type: \(swiftType)")
    }

    public func hasEncode() throws -> Bool {
        return true
    }

    public func encodeName() throws -> String {
        return generator.helperLibrary().name(.dictionaryEncode)
    }

    public func callEncode(entity: any TSExpr) throws -> any TSExpr {
        return try `default`.callEncode(
            genericArgs: [try value().swiftType],
            entity: entity
        )
    }

    public func encodeDecl() throws -> TSFunctionDecl? {
        throw MessageError("Unsupported type: \(swiftType)")
    }
}
