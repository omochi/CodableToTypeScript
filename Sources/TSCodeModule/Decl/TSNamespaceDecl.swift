public struct TSNamespaceDecl: PrettyPrintable {
    public init(
        name: String,
        decls: [TSDecl]
    ) {
        self.name = name
        self.decls = decls
    }

    public var name: String
    public var decls: [TSDecl]

    public func print(printer: PrettyPrinter) {
        printer.writeLine("export namespace \(name) {")
        printer.nest {
            for decl in decls {
                decl.print(printer: printer)
            }
        }
        printer.writeLine("}")
    }
}
