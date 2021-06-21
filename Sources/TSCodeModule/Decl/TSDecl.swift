public enum TSDecl: PrettyPrintable {
    case typeDecl(TSTypeDecl)
    case importDecl(TSImportDecl)
    case custom(String)

    public func print(printer: PrettyPrinter) {
        switch self {
        case .typeDecl(let d): d.print(printer: printer)
        case .importDecl(let d): d.print(printer: printer)
        case .custom(let text): printer.write(text)
        }
    }

    public static func typeDecl(
        name: String,
        genericParameters: [String] = [],
        type: TSType
    ) -> TSDecl {
        .typeDecl(TSTypeDecl(name: name, genericParameters: genericParameters, type: type))
    }

    public static func importDecl(names: [String], from: String) -> TSDecl {
        .importDecl(TSImportDecl(names: names, from: from))
    }
}
