import SwiftTypeReader

struct ErrorTypeConverter: TypeConverter {
    var generator: CodeGenerator
    var swiftType: any SType

    func hasDecode() throws -> Bool {
        throw MessageError("Error type can't be evaluated: \(swiftType)")
    }

    func hasEncode() throws -> Bool {
        throw MessageError("Error type can't be evaluated: \(swiftType)")
    }
}
