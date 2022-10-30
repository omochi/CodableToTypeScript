import SwiftTypeReader

struct TypeKey: Hashable {
    var location: Location?
    var name: String
    var genericArguments: [TypeKey]

    init(
        location: Location?,
        name: String,
        genericArguments: [TypeKey]
    ) {
        self.location = location
        self.name = name
        self.genericArguments = genericArguments
    }

    init(type: SType) throws {
        let location = type.regular?.location
        let name = type.name
        let genericArguments: [TypeKey] = try type.genericArguments().map { (arg) in
            try TypeKey(type: arg)
        }
        self.init(
            location: location,
            name: name,
            genericArguments: genericArguments
        )
    }
}
