import SwiftTypeReader

public struct TypeMap {
    public static let `default` = TypeMap(
        table: TypeMap.defaultTable
    )

    public static let defaultTable: [String: String] = [
        "Void": "void",
        "Bool": "boolean",
        "Int": "number",
        "Float": "number",
        "Double": "number",
        "String": "string"
    ]

    public init(
        table: [String : String]? = nil,
        closure: ((any TypeRepr) -> String?)? = nil
    ) {
        self.table = table ?? Self.defaultTable
        self.closure = closure
    }

    public var table: [String: String]

    public var closure: ((any TypeRepr) -> String?)?

    public func map(repr: any TypeRepr) -> String? {
        if let type = closure?(repr) {
            return type
        }

        if let type = mapFromTable(repr: repr) {
            return type
        }

        return nil
    }

    private func mapFromTable(repr: any TypeRepr) -> String? {
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
