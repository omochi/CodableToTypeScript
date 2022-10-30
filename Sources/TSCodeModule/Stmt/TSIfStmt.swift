public struct TSIfStmt: PrettyPrintable {
    public var condition: TSExpr
    public var then: TSStmt
    public var `else`: TSStmt?

    public init(
        condition: TSExpr,
        then: TSStmt,
        `else`: TSStmt? = nil
    ) {
        self.condition = condition
        self.then = then
        self.else = `else`
    }

    public func print(printer: PrettyPrinter) {
        printer.write("if (")
        condition.print(printer: printer)
        printer.write(") ")
        then.print(printer: printer)
        if let `else` = `else` {
            if !printer.isStartOfLine {
                printer.write(" ")
            }
            printer.write("else ")
            `else`.print(printer: printer)
        }
        if !printer.isStartOfLine {
            printer.writeLine("")
        }
    }
}
