import SwiftTypeReader

struct ErrorTypeConverter: TypeConverter {
    var generator: CodeGenerator
    var type: any SType

    func hasDecode() throws -> Bool {
        throw MessageError("Error type can't be evaluated: \(type)")
    }
}
