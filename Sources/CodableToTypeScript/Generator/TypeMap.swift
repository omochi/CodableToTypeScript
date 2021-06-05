public struct TypeMap {
    public static var `default`: TypeMap {
        TypeMap([
            "Void": "void",
            "Bool": "boolean",
            "Int": "number",
            "Float": "number",
            "Double": "number",
            "String": "string"
        ])
    }

    public init(_ table: [String : String] = [:]) {
        self.table = table
    }

    public var table: [String: String]

    public func map(name: String) -> String {
        table[name] ?? name
    }
}
