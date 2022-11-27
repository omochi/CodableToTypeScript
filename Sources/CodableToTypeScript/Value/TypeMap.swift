import SwiftTypeReader

public struct TypeMap {
    public struct Entry {
        public init(
            name: String,
            decode: String? = nil
        ) {
            self.name = name
            self.decode = decode
        }

        public var name: String
        public var decode: String?
    }

    public typealias MapFunction = (any SType) -> Entry?
    
    public static let `default` = TypeMap(
        table: TypeMap.defaultTable
    )

    public static let defaultTable: [String: Entry] = [
        "Void": Entry(name: "void"),
        "Bool": Entry(name: "boolean"),
        "Int": Entry(name: "number"),
        "Float": Entry(name: "number"),
        "Double": Entry(name: "number"),
        "String": Entry(name: "string")
    ]

    public init(
        table: [String : Entry]? = nil,
        mapFunction: MapFunction? = nil
    ) {
        self.table = table ?? Self.defaultTable
        self.mapFunction = mapFunction
    }

    public var table: [String: Entry]
    public var mapFunction: MapFunction?

    public func map(type: any SType) -> Entry? {
        if let entry = mapFunction?(type) {
            return entry
        }

        let repr = type.toTypeRepr(containsModule: false)

        if let type = mapFromTable(repr: repr) {
            return type
        }

        return nil
    }

    private func mapFromTable(repr: any TypeRepr) -> Entry? {
        guard let key = tableMapKey(repr: repr) else { return nil }
        return table[key]
    }

    private func tableMapKey(repr: any TypeRepr) -> String? {
        if let ident = repr.asIdent,
           let element = ident.elements.last {
            return element.name
        } else {
            return nil
        }
    }
}
