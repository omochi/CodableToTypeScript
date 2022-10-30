public struct TSObjectField: PrettyPrintable {
    public var name: TSExpr
    public var value: TSExpr

    public init(name: TSExpr, value: TSExpr) {
        self.name = name
        self.value = value
    }

    public func print(printer: PrettyPrinter) {
        printer.write(name)
        printer.write(": ")
        value.print(printer: printer)
    }
}

extension [TSObjectField] {
    public func print(printer: PrettyPrinter) {
        for (index, item) in enumerated() {
            item.print(printer: printer)
            if index < count - 1 {
                printer.write(",")
            }
            printer.writeLine("")
        }
    }
}
