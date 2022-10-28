public struct TSExprStmt: PrettyPrintable {
    public var expr: TSExpr

    public init(_ expr: TSExpr) {
        self.expr = expr
    }

    public func print(printer: PrettyPrinter) {
        expr.print(printer: printer)
        printer.writeLine(";")
    }
}