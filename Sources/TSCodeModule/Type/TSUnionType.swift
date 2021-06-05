public struct TSUnionType: PrettyPrintable {
    public init(_ items: [TSType]) {
        self.items = items
    }

    public var items: [TSType]

    public func print(printer: PrettyPrinter) {
        for (i, item) in items.enumerated() {
            printer.write(item)
            if i < items.count - 1 {
                printer.write(" | ")
            }
        }
    }
}
