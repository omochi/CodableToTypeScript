import SwiftTypeReader

public struct TypeMap {
    public struct Entry {
        public static func identity(name: String) -> Entry {
            return Entry(
                entityType: name,
                jsonType: name
            )
        }

        public static func coding(
            entityType: String,
            jsonType: String,
            decode: String?,
            encode: String?
        ) -> Entry {
            return Entry(
                entityType: entityType,
                jsonType: jsonType,
                decode: decode,
                encode: encode
            )
        }

        public var entityType: String
        public var jsonType: String
        public var decode: String?
        public var encode: String?

        public var symbols: Set<String> {
            var result: Set<String> = [
                entityType,
                jsonType
            ]
            if let t = decode {
                result.insert(t)
            }
            if let t = encode {
                result.insert(t)
            }
            return result
        }
    }

    public typealias MapFunction = (any SType) -> Entry?
    
    public static let `default` = TypeMap(
        table: TypeMap.defaultTable
    )

    public static let defaultTable: [String: Entry] = [
        "Void": .identity(name: "void"),
        "Bool": .identity(name: "boolean"),
        "Int": .identity(name: "number"),
        "Int8": .identity(name: "number"),
        "Int16": .identity(name: "number"),
        "Int32": .identity(name: "number"),
        "Int64": .identity(name: "number"),
        "UInt8": .identity(name: "number"),
        "UInt16": .identity(name: "number"),
        "UInt32": .identity(name: "number"),
        "UInt64": .identity(name: "number"),
        "Float": .identity(name: "number"),
        "Float32": .identity(name: "number"),
        "Float64": .identity(name: "number"),
        "Double": .identity(name: "number"),
        "Character": .identity(name: "string"),
        "String": .identity(name: "string"),
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

    public var entries: [Entry] { Array(table.values) }

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
