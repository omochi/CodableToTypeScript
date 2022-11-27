import SwiftTypeReader

public struct RawTypeConverter: TypeConverter {
    public init(
        generator: CodeGenerator,
        type: any SType,
        tsType: String
    ) {
        self.generator = generator
        self.type = type
        self.tsType = tsType
    }

    public var generator: CodeGenerator
    public var type: any SType
    public var tsType: String

    public func hasJSONType() throws -> Bool {
        return false
    }
}
