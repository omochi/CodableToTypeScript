import SwiftTypeReader

struct GenericParamConverter: TypeConverter {
    var generator: CodeGenerator
    var param: GenericParamType
    var type: any SType { param }

    func hasJSONType() throws -> Bool {
        return true
    }
}
