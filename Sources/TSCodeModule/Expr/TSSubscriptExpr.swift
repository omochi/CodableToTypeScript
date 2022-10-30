public struct TSSubscriptExpr: PrettyPrintable {
    public var base: TSExpr
    public var key: TSExpr

    public init(base: TSExpr, key: TSExpr) {
        self.base = base
        self.key = key
    }

    public func print(printer: PrettyPrinter) {
        base.print(printer: printer)
        printer.write("[")
        key.print(printer: printer)
        printer.write("]")
    }
}
