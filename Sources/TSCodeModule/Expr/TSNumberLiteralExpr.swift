public struct TSNumberLiteralExpr: PrettyPrintable {
    public var text: String

    public init(_ text: String) {
        self.text = text
    }

    public func print(printer: PrettyPrinter) {
        printer.write(text)
    }
}
