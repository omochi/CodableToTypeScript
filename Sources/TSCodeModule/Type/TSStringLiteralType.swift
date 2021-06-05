public struct TSStringLiteralType: PrettyPrintable {
    public init(_ value: String) {
        self.value = value
    }

    public var value: String

    public func print(printer: PrettyPrinter) {
        printer.write("\"")
        printer.write(value)
        printer.write("\"")
    }
}
