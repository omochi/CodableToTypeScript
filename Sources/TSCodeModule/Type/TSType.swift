public enum TSType: PrettyPrintable {
    case named(TSNamedType)
    case record(TSRecordType)
    case union(TSUnionType)
    case stringLiteral(TSStringLiteralType)

    public func print(printer: PrettyPrinter) {
        switch self {
        case .named(let t): t.print(printer: printer)
        case .record(let t): t.print(printer: printer)
        case .union(let t): t.print(printer: printer)
        case .stringLiteral(let t): t.print(printer: printer)
        }
    }


    public static func named(_ name: String) -> TSType {
        .named(TSNamedType(name))
    }

    public static func record(_ fields: [TSRecordType.Field]) -> TSType {
        .record(TSRecordType(fields))
    }

    public static func union(_ items: [TSType]) -> TSType {
        .union(TSUnionType(items))
    }

    public static func stringLiteral(_ value: String) -> TSType {
        .stringLiteral(TSStringLiteralType(value))
    }
}
