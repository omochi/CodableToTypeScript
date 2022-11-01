public indirect enum TSExpr: PrettyPrintable {
    case call(TSCallExpr)
    case closure(TSClosureExpr)
    case identifier(TSIdentifierExpr)
    case infixOperator(TSInfixOperatorExpr)
    case memberAccess(TSMemberAccessExpr)
    case new(TSNewExpr)
    case numberLiteral(TSNumberLiteralExpr)
    case object(TSObjectExpr)
    case prefixOperator(TSPrefixOperatorExpr)
    case stringLiteral(TSStringLiteralExpr)
    case `subscript`(TSSubscriptExpr)
    case type(TSTypeExpr)
    case custom(TSCustomExpr)

    public func print(printer r: PrettyPrinter) {
        switch self {
        case .call(let e): e.print(printer: r)
        case .closure(let e): e.print(printer: r)
        case .identifier(let e): e.print(printer: r)
        case .infixOperator(let e): e.print(printer: r)
        case .memberAccess(let e): e.print(printer: r)
        case .new(let e): e.print(printer: r)
        case .numberLiteral(let e): e.print(printer: r)
        case .object(let e): e.print(printer: r)
        case .prefixOperator(let e): e.print(printer: r)
        case .stringLiteral(let e): e.print(printer: r)
        case .subscript(let e): e.print(printer: r)
        case .type(let e): e.print(printer: r)
        case .custom(let e): e.print(printer: r)
        }
    }

    public static func call(callee: TSExpr, arguments: [TSFunctionArgument]) -> TSExpr {
        .call(TSCallExpr(
            callee: callee, arguments: arguments
        ))
    }

    public static func closure(parameters: [TSFunctionParameter], returnType: TSType?, body: TSStmt) -> TSExpr {
        .closure(TSClosureExpr(parameters: parameters, returnType: returnType, body: body))
    }

    public static func identifier(_ name: String) -> TSExpr {
        .identifier(TSIdentifierExpr(name))
    }

    public static func infixOperator(_ left: TSExpr, _ `operator`: String, _ right: TSExpr) -> TSExpr {
        .infixOperator(TSInfixOperatorExpr(
            left, `operator`, right
        ))
    }

    public static func new(callee: TSExpr, arguments: [TSFunctionArgument]) -> TSExpr {
        .new(TSNewExpr(
            callee: callee, arguments: arguments
        ))
    }

    public static func numberLiteral(_ text: String) -> TSExpr {
        .numberLiteral(TSNumberLiteralExpr(text))
    }

    public static func memberAccess(base: TSExpr, name: String) -> TSExpr {
        .memberAccess(TSMemberAccessExpr(
            base: base, name: name
        ))
    }

    public static func object(_ fields: [TSObjectField]) -> TSExpr {
        .object(TSObjectExpr(fields))
    }

    public static func prefixOperator(_ `operator`: String, _ expr: TSExpr) -> TSExpr {
        .prefixOperator(TSPrefixOperatorExpr(`operator`, expr))
    }

    public static func stringLiteral(_ text: String) -> TSExpr {
        .stringLiteral(TSStringLiteralExpr(text))
    }

    public static func `subscript`(base: TSExpr, key: TSExpr) -> TSExpr {
        .subscript(TSSubscriptExpr(base: base, key: key))
    }

    public static func type(_ type: TSType) -> TSExpr {
        .type(TSTypeExpr(type))
    }

    public static func custom(_ text: String) -> TSExpr {
        .custom(TSCustomExpr(text))
    }
}
