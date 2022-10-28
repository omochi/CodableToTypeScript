public struct TSReturnExpr: PrettyPrintable {
    public var expr: TSExpr

    public init(_ expr: TSExpr) {
        self.expr = expr
    }

    public func print(printer: PrettyPrinter) {
        printer.write("return ")
        expr.print(printer: printer)
    }
}
