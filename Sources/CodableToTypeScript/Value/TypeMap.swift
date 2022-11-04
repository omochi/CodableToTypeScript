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
        closure: ((TypeSpecifier) -> String?)? = nil
    ) {
        self.table = table ?? Self.defaultTable
        self.closure = closure
    }

    public var table: [String: String]

    public var closure: ((TypeSpecifier) -> String?)?

    public func map(specifier: TypeSpecifier) -> String? {
        if let type = closure?(specifier) {
            return type
        }

        let element = specifier.lastElement

        let name = element.name

        if let type = table[name] {
            return type
        }

        return nil
    }
}
