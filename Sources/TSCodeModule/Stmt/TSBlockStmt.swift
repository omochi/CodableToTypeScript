public struct TSBlockStmt: PrettyPrintable {
    public var items: [TSBlockItem]

    public init(_ items: [TSBlockItem]) {
        self.items = items
    }

    public func print(printer: PrettyPrinter) {
        printer.writeLine("{")
        printer.nest {
            items.print(printer: printer)
        }
        printer.write("}")
    }
}
