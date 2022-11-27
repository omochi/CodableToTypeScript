import SwiftTypeReader

struct ArrayConverter: TypeConverter {
    var gen: CodeGenerator
    var type: any SType

    func hasJSONType() throws -> Bool {
        let (_, element) = type.asArray()!
        return try gen.hasJSONType(type: element)
    }
}
