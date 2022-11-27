import SwiftTypeReader

struct OptionalConverter: TypeConverter {
    var gen: CodeGenerator
    var type: any SType

    func hasJSONType() throws -> Bool {
        let (wrapped, _) = type.unwrapOptional(limit: nil)!
        return try gen.hasJSONType(type: wrapped)
    }
}
