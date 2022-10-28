public struct TSBlockStmt: PrettyPrintable {
    public var stmts: [TSStmt]

    public init(_ stmts: [TSStmt]) {
        self.stmts = stmts
    }

    public func print(printer: PrettyPrinter) {
        printer.writeLine("{")
        printer.nest {
            for stmt in stmts {
                stmt.print(printer: printer)
            }
        }
        printer.write("}")
    }
}
