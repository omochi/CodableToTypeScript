public indirect enum TSExpr: PrettyPrintable {
    case call(TSCallExpr)
    case identifier(TSIdentifierExpr)
    case memberAccess(TSMemberAccessExpr)
    case object(TSObjectExpr)
    case `return`(TSReturnExpr)
    case custom(TSCustomExpr)

    public func print(printer r: PrettyPrinter) {
        switch self {
        case .call(let e): e.print(printer: r)
        case .identifier(let e): e.print(printer: r)
        case .memberAccess(let e): e.print(printer: r)
        case .object(let e): e.print(printer: r)
        case .return(let e): e.print(printer: r)
        case .custom(let e): e.print(printer: r)
        }
    }

    public static func call(callee: TSExpr, arguments: [TSExpr]) -> TSExpr {
        .call(TSCallExpr(
            callee: callee, arguments: arguments
        ))
    }

    public static func identifier(_ name: String) -> TSExpr {
        .identifier(TSIdentifierExpr(name))
    }

    public static func `return`(_ expr: TSExpr) -> TSExpr {
        .return(TSReturnExpr(expr))
    }

    public static func custom(_ text: String) -> TSExpr {
        .custom(TSCustomExpr(text))
    }
}
