public indirect enum TSStmt: PrettyPrintable {
    case block(TSBlockStmt)
    case expr(TSExprStmt)
    case `if`(TSIfStmt)
    case `return`(TSReturnStmt)
    case `throw`(TSThrowStmt)

    public func print(printer r: PrettyPrinter) {
        switch self {
        case .block(let s): s.print(printer: r)
        case .expr(let s): s.print(printer: r)
        case .if(let s): s.print(printer: r)
        case .return(let s): s.print(printer: r)
        case .throw(let s): s.print(printer: r)
        }
    }

    public static func block(_ stmts: [TSStmt]) -> TSStmt {
        .block(TSBlockStmt(stmts))
    }

    public static func expr(_ expr: TSExpr) -> TSStmt {
        .expr(TSExprStmt(expr))
    }

    public static func `return`(_ expr: TSExpr) -> TSStmt {
        .return(TSReturnStmt(expr))
    }

    public static func `throw`(_ expr: TSExpr) -> TSStmt {
        .throw(TSThrowStmt(expr))
    }

}
