public enum TSDecl: PrettyPrintable {
    case `class`(TSClassDecl)
    case field(TSFieldDecl)
    case function(TSFunctionDecl)
    case `import`(TSImportDecl)
    case interface(TSInterfaceDecl)
    case method(TSMethodDecl)
    case namespace(TSNamespaceDecl)
    case type(TSTypeDecl)
    case `var`(TSVarDecl)
    case custom(TSCustomDecl)

    public func print(printer r: PrettyPrinter) {
        switch self {
        case .class(let d): d.print(printer: r)
        case .field(let d): d.print(printer: r)
        case .function(let d): d.print(printer: r)
        case .import(let d): d.print(printer: r)
        case .interface(let d): d.print(printer: r)
        case .method(let d): d.print(printer: r)
        case .namespace(let d): d.print(printer: r)
        case .type(let d): d.print(printer: r)
        case .`var`(let d): d.print(printer: r)
        case .custom(let d): d.print(printer: r)
        }
    }

    public func wantsNewlineBetweenSiblingDecl(scope: BlockScope) -> Bool {
        switch self {
        case .class:
            return true
        case .field:
            return false
        case .import:
            return false
        case .interface:
            return true
        case .method, .function:
            switch scope {
            case .interface:
                return false
            default:
                return true
            }
        case .namespace:
            return true
        case .type:
            return true
        case .var:
            switch scope {
            case .global:
                return true
            default:
                return false
            }
        case .custom:
            return true
        }
    }

    public static func type(
        export: Bool = true,
        name: String,
        genericParameters: [TSGenericParameter] = .init(),
        type: TSType
    ) -> TSDecl {
        .type(TSTypeDecl(export: export, name: name, genericParameters: genericParameters, type: type))
    }

    public static func `import`(names: [String], from: String) -> TSDecl {
        .import(TSImportDecl(names: names, from: from))
    }

    public static func `var`(
        export: Bool = false,
        kind: String,
        name: String,
        type: TSType? = nil,
        initializer: TSExpr? = nil
    ) -> TSDecl {
        .`var`(TSVarDecl(
            export: export,
            kind: kind,
            name: name,
            type: type,
            initializer: initializer
        ))
    }

    public static func custom(_ text: String) -> TSDecl {
        .custom(TSCustomDecl(text))
    }
}

public func isSameKind(lhs: TSDecl, rhs: TSDecl) -> Bool {
    switch (lhs, rhs) {
    case (.`class`, .`class`):
        return true
    case (.field, .field):
        return true
    case (.function, .function):
        return true
    case (.`import`, .`import`):
        return true
    case (.interface, .interface):
        return true
    case (.method, .method):
        return true
    case (.namespace, .namespace):
        return true
    case (.type, .type):
        return true
    case (.`var`, .`var`):
        return true
    case (.custom, .custom):
        return false
    default:
        return false
    }
}
