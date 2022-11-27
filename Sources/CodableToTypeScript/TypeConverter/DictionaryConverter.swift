import SwiftTypeReader

struct DictionaryConverter: TypeConverter {
    var gen: CodeGenerator
    var type: any SType

    func hasJSONType() throws -> Bool {
        let (_, value) = type.asDictionary()!
        return try gen.hasJSONType(type: value)
    }
}
