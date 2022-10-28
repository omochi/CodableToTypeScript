public indirect enum TSExpr: PrettyPrintable {
    case call(TSCallExpr)
    case identifier(TSIdentifierExpr)
    case infixOperator(TSInfixOperatorExpr)
    case memberAccess(TSMemberAccessExpr)
    case new(TSNewExpr)
    case object(TSObjectExpr)
    case stringLiteral(TSStringLiteralExpr)
    case custom(TSCustomExpr)

    public func print(printer r: PrettyPrinter) {
        switch self {
        case .call(let e): e.print(printer: r)
        case .identifier(let e): e.print(printer: r)
        case .infixOperator(let e): e.print(printer: r)
        case .memberAccess(let e): e.print(printer: r)
        case .new(let e): e.print(printer: r)
        case .object(let e): e.print(printer: r)
        case .stringLiteral(let e): e.print(printer: r)
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

    public static func infixOperator(_ left: TSExpr, _ `operator`: String, _ right: TSExpr) -> TSExpr {
        .infixOperator(TSInfixOperatorExpr(
            left, `operator`, right
        ))
    }

    public static func new(callee: TSExpr, arguments: [TSExpr]) -> TSExpr {
        .new(TSNewExpr(
            callee: callee, arguments: arguments
        ))
    }

    public static func memberAccess(base: TSExpr, name: String) -> TSExpr {
        .memberAccess(TSMemberAccessExpr(
            base: base, name: name
        ))
    }

    public static func object(_ fields: [TSObjectField]) -> TSExpr {
        .object(TSObjectExpr(fields))
    }

    public static func stringLiteral(_ text: String) -> TSExpr {
        .stringLiteral(TSStringLiteralExpr(text))
    }

    public static func custom(_ text: String) -> TSExpr {
        .custom(TSCustomExpr(text))
    }
}
