public struct TSStringLiteralExpr: PrettyPrintable {
    public var text: String

    public init(_ text: String) {
        self.text = text
    }

    public func print(printer: PrettyPrinter) {
        var text = text
        text = text.replacingOccurrences(of: "\\", with: "\\\\")
        text = text.replacingOccurrences(of: "\"", with: "\\\"")

        printer.write("\"")
        printer.write(text)
        printer.write("\"")
    }
}
