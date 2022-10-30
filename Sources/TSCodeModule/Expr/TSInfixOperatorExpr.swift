public struct TSInfixOperatorExpr: PrettyPrintable {
    public var left: TSExpr
    public var `operator`: String
    public var right: TSExpr

    public init(
        _ left: TSExpr,
        _ `operator`: String,
        _ right: TSExpr
    ) {
        self.left = left
        self.operator = `operator`
        self.right = right
    }

    public func print(printer: PrettyPrinter) {
        left.print(printer: printer)
        printer.write(" \(`operator`) ")
        right.print(printer: printer)
    }
}
