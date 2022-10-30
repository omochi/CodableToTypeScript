public struct TSUnionType: PrettyPrintable {
    public init(
        _ items: [TSType]
    ) {
        self.items = items
    }

    public var items: [TSType]
    
    public func print(printer: PrettyPrinter) {
        let isBig = items.count > printer.smallNumber

        for (i, item) in items.enumerated() {
            let line = printer.line
            printer.write(item)
            if i < items.count - 1 {
                if line == printer.line, isBig {
                    printer.writeLine(" |")
                } else {
                    printer.write(" | ")
                }
            }
        }
    }
}
