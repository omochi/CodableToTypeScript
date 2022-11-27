import SwiftTypeReader

struct StructConverter: TypeConverter {
    var gen: CodeGenerator
    var type: StructType

    func hasJSONType() throws -> Bool {
        for field in type.decl.storedProperties {
            if try gen.converter(for: field.interfaceType).hasJSONType() {
                return true
            }
        }
        return false
    }
}
