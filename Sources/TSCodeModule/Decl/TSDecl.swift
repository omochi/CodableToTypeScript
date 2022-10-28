public enum TSDecl: PrettyPrintable {
    case function(TSFunctionDecl)
    case `import`(TSImportDecl)
    case namespace(TSNamespaceDecl)
    case type(TSTypeDecl)
    case `var`(TSVarDecl)
    case custom(TSCustomDecl)

    public func print(printer r: PrettyPrinter) {
        switch self {
        case .function(let d): d.print(printer: r)
        case .import(let d): d.print(printer: r)
        case .namespace(let d): d.print(printer: r)
        case .type(let d): d.print(printer: r)
        case .var(let d): d.print(printer: r)
        case .custom(let d): d.print(printer: r)
        }
    }

    public static func type(
        name: String,
        genericParameters: TSGenericParameters = .init(),
        type: TSType
    ) -> TSDecl {
        .type(TSTypeDecl(name: name, genericParameters: genericParameters, type: type))
    }

    public static func `import`(names: [String], from: String) -> TSDecl {
        .import(TSImportDecl(names: names, from: from))
    }

    public static func `var`(mode: String, name: String, initializer: TSExpr? = nil) -> TSDecl {
        .var(TSVarDecl(mode: mode, name: name, initializer: initializer))
    }

    public static func custom(_ text: String) -> TSDecl {
        .custom(TSCustomDecl(text))
    }
}
