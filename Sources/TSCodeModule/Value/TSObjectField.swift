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
