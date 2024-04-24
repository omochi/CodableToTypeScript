import SwiftTypeReader
import TypeScriptAST

public struct SetConverter: TypeConverter {
    public init(generator: CodeGenerator, swiftType: any SType) {
        self.generator = generator
        self.swiftType = swiftType
    }

    public var generator: CodeGenerator
    public var swiftType: any SType

    private func element() throws -> any TypeConverter {
        let (_, element) = swiftType.asSet()!
        return try generator.converter(for: element)
    }

    public func type(for target: GenerationTarget) throws -> any TSType {
        switch target {
        case .entity:
            return try `default`.type(for: target)
        case .json:
            return TSArrayType(try element().type(for: target))
        }
    }

    public func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        throw MessageError("Unsupported type: \(swiftType)")
    }

    public func hasDecode() throws -> Bool {
        return true
    }

    public func decodeName() throws -> String {
        return generator.helperLibrary().name(.setDecode)
    }

    public func decodeDecl() throws -> TSFunctionDecl? {
        throw MessageError("Unsupported type: \(swiftType)")
    }

    public func hasEncode() throws -> Bool {
        return true
    }

    public func encodeName() throws -> String {
        return generator.helperLibrary().name(.setEncode)
    }

    public func encodeDecl() throws -> TSFunctionDecl? {
        throw MessageError("Unsupported type: \(swiftType)")
    }
}
