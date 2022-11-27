import SwiftTypeReader

public struct ClosureConverter: TypeConverter {
    public init(
        generator: CodeGenerator,
        type: any SType
    ) {
        self.generator = generator
        self.type = type
    }

    public var generator: CodeGenerator
    public var type: any SType

    public func hasJSONType() throws -> Bool {
        return false
    }
}
