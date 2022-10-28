public struct TSUnionType: PrettyPrintable {
    public init(
        _ items: [TSType]
    ) {
        self.items = items
    }

    public var items: [TSType]

    public func print(printer: PrettyPrinter) {
        let isLong = items.count > 3

        for (i, item) in items.enumerated() {
            let line = printer.line
            printer.write(item)
            if i < items.count - 1 {
                if line == printer.line, isLong {
                    printer.writeLine(" |")
                } else {
                    printer.write(" | ")
                }
            }
        }
    }
}
