public struct TSIdentifierExpr: PrettyPrintable {
    public var name: String

    public init(_ name: String) {
        self.name = name
    }

    public static let null = TSIdentifierExpr("null")
    public static let undefined = TSIdentifierExpr("undefined")

    public func print(printer: PrettyPrinter) {
        printer.write(name)
    }
}
