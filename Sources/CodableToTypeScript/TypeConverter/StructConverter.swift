import SwiftTypeReader

struct StructConverter: TypeConverter {
    var gen: CodeGenerator
    var type: StructType

    func hasJSONType() throws -> Bool {
        for field in type.decl.storedProperties {
            if try gen.hasJSONType(type: field.interfaceType) {
                return true
            }
        }
        return false
    }
}
