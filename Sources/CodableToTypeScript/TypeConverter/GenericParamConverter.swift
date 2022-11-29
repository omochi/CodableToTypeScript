import SwiftTypeReader

struct GenericParamConverter: TypeConverter {
    var generator: CodeGenerator
    var param: GenericParamType
    var swiftType: any SType { param }

    func hasDecode() throws -> Bool {
        return true
    }

    func hasEncode() throws -> Bool {
        return true
    }
}
