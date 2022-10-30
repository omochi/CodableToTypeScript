public struct TSVarDecl: PrettyPrintable {
    public var kind: String
    public var name: String
    public var type: TSType?
    public var initializer: TSExpr?

    public init(
        kind: String,
        name: String,
        type: TSType? = nil,
        initializer: TSExpr? = nil
    ) {
        self.kind = kind
        self.name = name
        self.type = type
        self.initializer = initializer
    }

    public func print(printer: PrettyPrinter) {
        printer.write("\(kind) \(name)")
        if let type = type {
            printer.write(": ")
            type.print(printer: printer)
        }
        if let initializer = initializer {
            printer.write(" = ")
            initializer.print(printer: printer)
        }
        printer.writeLine(";")
    }
}
