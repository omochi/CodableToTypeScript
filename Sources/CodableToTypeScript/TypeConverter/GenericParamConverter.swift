import SwiftTypeReader

struct GenericParamConverter: TypeConverter {
    var gen: CodeGenerator
    var type: GenericParamType

    func hasJSONType() throws -> Bool {
        return true
    }
}
