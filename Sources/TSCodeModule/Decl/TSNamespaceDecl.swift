public struct TSNamespaceDecl: PrettyPrintable {
    public init(
        export: Bool = true,
        name: String,
        decls: [TSDecl]
    ) {
        self.export = export
        self.name = name
        self.decls = decls
    }

    public var export: Bool
    public var name: String
    public var decls: [TSDecl]

    public func print(printer: PrettyPrinter) {
        if export {
            printer.write("export")
        }
        printer.writeUnlessStartOfLine(" ")
        printer.writeLine("namespace \(name) {")
        printer.nest {
            for decl in decls {
                decl.print(printer: printer)
            }
        }
        printer.writeLine("}")
    }
}
