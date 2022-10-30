public struct TSForStmt: PrettyPrintable {
    public var kind: String
    public var name: String
    public var `operator`: String
    public var expr: TSExpr
    public var body: TSStmt

    public init(
        kind: String,
        name: String,
        `operator`: String,
        expr: TSExpr,
        body: TSStmt
    ) {
        self.kind = kind
        self.name = name
        self.operator = `operator`
        self.expr = expr
        self.body = body
    }

    public func print(printer: PrettyPrinter) {
        printer.write("for (\(kind) \(name) \(`operator`) ")
        expr.print(printer: printer)
        printer.write(") ")
        body.print(printer: printer)
        if !printer.isStartOfLine {
            printer.writeLine("")
        }
    }
}
