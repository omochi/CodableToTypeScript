import SwiftTypeReader
import TypeScriptAST

public struct StaticConverter: TypeConverter {
    public init(
        generator: CodeGenerator,
        type: any SType,
        tsName: String
    ) {
        self.generator = generator
        self.type = type
        self.tsName = tsName
    }

    public var generator: CodeGenerator
    public var type: any SType
    private var tsName: String

    public func hasJSONType() throws -> Bool {
        return false
    }

    public func type(for target: GenerationTarget) throws -> any TSType {
        let args = try genericArgs().map { try $0.type(for: target) }
        return TSIdentType(tsName, genericArgs: args)
    }
}
