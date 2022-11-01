public struct TSPrefixOperatorExpr: PrettyPrintable {
    public var `operator`: String
    public var expr: TSExpr

    public init(_ `operator`: String, _ expr: TSExpr) {
        self.operator = `operator`
        self.expr = expr
    }

    public func print(printer: PrettyPrinter) {
        printer.write("\(`operator`) ")
        expr.print(printer: printer)
    }
}
