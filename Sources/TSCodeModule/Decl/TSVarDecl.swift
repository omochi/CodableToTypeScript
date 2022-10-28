public struct TSVarDecl: PrettyPrintable {
    public var mode: String
    public var name: String
    public var initializer: TSExpr?

    public init(
        mode: String,
        name: String,
        initializer: TSExpr? = nil
    ) {
        self.mode = mode
        self.name = name
        self.initializer = initializer
    }

    public func print(printer: PrettyPrinter) {
        printer.write("\(mode) \(name)")
        if let initializer = initializer {
            printer.write(" = ")
            initializer.print(printer: printer)
        }
        printer.writeLine(";")
    }
}
