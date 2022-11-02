public enum TSBlockItem: PrettyPrintable {
    case decl(TSDecl)
    case stmt(TSStmt)
    case expr(TSExpr)

    public var decl: TSDecl? {
        switch self {
        case .decl(let x): return x
        default: return nil
        }
    }

    public var stmt: TSStmt? {
        switch self {
        case .stmt(let x): return x
        default: return nil
        }
    }

    public var expr: TSExpr? {
        switch self {
        case .expr(let x): return x
        default: return nil
        }
    }

    public func print(printer: PrettyPrinter) {
        switch self {
        case .decl(let x):
            x.print(printer: printer)
        case .stmt(let x):
            x.print(printer: printer)
        case .expr(let x):
            x.print(printer: printer)
            printer.writeLine(";")
        }
    }
}

extension [TSBlockItem] {
    public func print(printer: PrettyPrinter) {
        for (index, item) in enumerated() {
            if index > 0,
               let prevDecl = self[index - 1].decl,
               let itemDecl = item.decl
            {
                let isSame = isSameKind(lhs: prevDecl, rhs: itemDecl)
                if !isSame || itemDecl.wantsNewlineBetweenSiblingDecl(scope: printer.blockScope) {
                    printer.writeLine("")
                }
            }

            item.print(printer: printer)
        }
    }
}
