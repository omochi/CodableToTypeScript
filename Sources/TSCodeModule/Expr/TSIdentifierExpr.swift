public struct TSIdentifierExpr: PrettyPrintable {
    public var name: String

    public init(_ name: String) {
        self.name = name
    }

    public func print(printer: PrettyPrinter) {
        printer.write(name)
    }
}
