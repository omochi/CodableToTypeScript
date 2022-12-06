import SwiftTypeReader

public struct TypeMap {
    public enum Entry {
        case identity(name: String)
        case coding(entityType: String, jsonType: String, decode: String?, encode: String?)

        internal var entityType: String {
            switch self {
            case .identity(name: let name): return name
            case .coding(entityType: let name, _, _, _): return name
            }
        }

        internal var jsonType: String {
            switch self {
            case .identity(name: let name): return name
            case .coding(_, jsonType: let name, _, _): return name
            }
        }

        internal var decode: String? {
            switch self {
            case .identity: return nil
            case .coding(_, _, decode: let name, _): return name
            }
        }

        internal var encode: String? {
            switch self {
            case .identity: return nil
            case .coding(_, _, _, encode: let name): return name
            }
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
        "Float": .identity(name: "number"),
        "Double": .identity(name: "number"),
        "String": .identity(name: "string")
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
