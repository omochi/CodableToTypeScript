public struct TSThrowStmt: PrettyPrintable {
    public var expr: TSExpr

    public init(_ expr: TSExpr) {
        self.expr = expr
    }

    public func print(printer: PrettyPrinter) {
        printer.write("throw ")
        expr.print(printer: printer)
        printer.writeLine(";")
    }
}
