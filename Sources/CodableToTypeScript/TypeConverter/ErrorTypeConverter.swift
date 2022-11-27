import SwiftTypeReader

struct ErrorTypeConverter: TypeConverter {
    var gen: CodeGenerator
    var type: any SType

    func hasJSONType() throws -> Bool {
        throw MessageError("Error type can't be evaluated: \(type)")
    }
}
