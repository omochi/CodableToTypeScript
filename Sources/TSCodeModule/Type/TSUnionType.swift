public struct TSUnionType: PrettyPrintable {
    public init(
        _ items: [TSType],
        splitLines: Bool = false
    ) {
        self.items = items
        self.splitLines = splitLines
    }

    public var items: [TSType]
    public var splitLines: Bool

    public func print(printer: PrettyPrinter) {
        for (i, item) in items.enumerated() {
            printer.write(item)
            if i < items.count - 1 {
                if splitLines {
                    printer.writeLine(" |")
                } else {
                    printer.write(" | ")
                }
            }
        }
    }
}
