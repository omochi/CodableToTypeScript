public struct TSUnionType: PrettyPrintable {
    public init(
        _ items: [TSType]
    ) {
        self.items = items
    }

    public var items: [TSType]

    public func print(printer: PrettyPrinter) {
        var column = 0
        for (i, item) in items.enumerated() {
            let line = printer.line
            printer.write(item)
            if i < items.count - 1 {
                if line != printer.line {
                    column = 0
                } else {
                    column += 1
                }

                if column >= 3 {
                    printer.writeLine(" |")
                    column = 0
                } else {
                    printer.write(" | ")
                }
            }
        }
    }
}
