import SwiftTypeReader

struct GenericParamConverter: TypeConverter {
    var generator: CodeGenerator
    var param: GenericParamType
    var type: any SType { param }

    func hasDecode() throws -> Bool {
        return true
    }
}
