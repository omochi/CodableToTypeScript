import SwiftTypeReader

struct EnumConverter: TypeConverter {
    var gen: CodeGenerator
    var type: EnumType

    func hasJSONType() throws -> Bool {
        if type.decl.caseElements.isEmpty {
            return false
        } else if type.hasStringRawValue() {
            return false
        } else {
            return true
        }
    }
}
