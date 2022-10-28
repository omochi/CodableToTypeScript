public enum TSBlockItem: PrettyPrintable {
    case decl(TSDecl)
    case stmt(TSStmt)
    case expr(TSExpr)

    public func print(printer: PrettyPrinter) {
        switch self {
        case .decl(let x):
            x.print(printer: printer)
        case .stmt(let x):
            x.print(printer: printer)
        case .expr(let x):
            x.print(printer: printer)
            printer.writeLine("")
        }
    }
}
