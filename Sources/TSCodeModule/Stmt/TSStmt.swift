public indirect enum TSStmt: PrettyPrintable {
    case block(TSBlockStmt)
    case `if`(TSIfStmt)
    case `return`(TSReturnStmt)
    case `throw`(TSThrowStmt)
    case custom(TSCustomStmt)

    public func print(printer r: PrettyPrinter) {
        switch self {
        case .block(let s): s.print(printer: r)
        case .if(let s): s.print(printer: r)
        case .return(let s): s.print(printer: r)
        case .throw(let s): s.print(printer: r)
        case .custom(let s): s.print(printer: r)
        }
    }

    public static func block(_ items: [TSBlockItem]) -> TSStmt {
        .block(TSBlockStmt(items))
    }
    
    public static func `return`(_ expr: TSExpr) -> TSStmt {
        .return(TSReturnStmt(expr))
    }

    public static func `throw`(_ expr: TSExpr) -> TSStmt {
        .throw(TSThrowStmt(expr))
    }

    public static func custom(_ text: String) -> TSStmt {
        .custom(TSCustomStmt(text))
    }
}
