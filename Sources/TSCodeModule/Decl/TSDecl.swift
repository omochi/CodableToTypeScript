public enum TSDecl: PrettyPrintable {
    case typeDecl(TSTypeDecl)
    case custom(String)

    public func print(printer: PrettyPrinter) {
        switch self {
        case .typeDecl(let d):
            d.print(printer: printer)
        case .custom(let text):
            printer.write(text)
        }
    }

    public static func typeDecl(name: String, type: TSType) -> TSDecl {
        .typeDecl(TSTypeDecl(name: name, type: type))
    }
}
