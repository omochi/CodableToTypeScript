public enum TSDecl: PrettyPrintable {
    case `class`(TSClassDecl)
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
        case .function(let d): d.print(printer: r)
        case .import(let d): d.print(printer: r)
        case .interface(let d): d.print(printer: r)
        case .method(let d): d.print(printer: r)
        case .namespace(let d): d.print(printer: r)
        case .type(let d): d.print(printer: r)
        case .var(let d): d.print(printer: r)
        case .custom(let d): d.print(printer: r)
        }
    }

    public var wantsTrailingNewline: Bool {
        switch self {
        case .`var`(let d): return d.wantsTrailingNewline
        case .custom: return false
        default: return true
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
        initializer: TSExpr? = nil,
        wantsTrailingNewline: Bool = false
    ) -> TSDecl {
        .var(TSVarDecl(
            export: export,
            kind: kind,
            name: name,
            type: type,
            initializer: initializer,
            wantsTrailingNewline: wantsTrailingNewline
        ))
    }

    public static func custom(_ text: String) -> TSDecl {
        .custom(TSCustomDecl(text))
    }
}
