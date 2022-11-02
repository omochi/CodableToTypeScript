public struct TSInterfaceDecl: PrettyPrintable {
    public var export: Bool
    public var name: String
    public var genericParameters: [TSGenericParameter]
    public var extends: [TSType]?
    public var decls: [TSDecl]

    public init(
        export: Bool = true,
        name: String,
        genericParameters: [TSGenericParameter] = [],
        extends: [TSType]? = nil,
        decls: [TSDecl]
    ) {
        self.export = export
        self.name = name
        self.genericParameters = genericParameters
        self.extends = extends
        self.decls = decls
    }

    public func print(printer: PrettyPrinter) {
        if export {
            printer.write("export")
        }
        printer.writeUnlessStartOfLine(" ")
        printer.write("interface \(name)")
        genericParameters.print(printer: printer)
        if let extends {
            printer.write(" extends")
            extends.print(printer: printer)
        }
        printer.writeUnlessStartOfLine(" ")
        printer.writeLine("{")
        printer.with(blockScope: .interface) {
            printer.nest {
                decls.map { TSBlockItem.decl($0) }.print(printer: printer)
            }
        }
        printer.writeLine("}")
    }
}
