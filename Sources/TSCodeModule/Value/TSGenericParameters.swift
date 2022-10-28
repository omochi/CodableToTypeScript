public struct TSGenericParameters: PrettyPrintable {
    public var items: [String]

    public init(items: [String] = []) {
        self.items = items
    }

    public func print(printer: PrettyPrinter) {
        if items.isEmpty { return }

        printer.write("<")
        printer.write(items.joined(separator: ", "))
        printer.write(">")
    }
}
