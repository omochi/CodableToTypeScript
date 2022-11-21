import SwiftTypeReader

struct TypeKey: Hashable {
    init(type: any SType) {
        self.type = type
    }

    @AnyTypeStorage var type: any SType
}
