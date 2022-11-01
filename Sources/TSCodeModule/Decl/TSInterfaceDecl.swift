public struct TSInterfaceDecl: PrettyPrintable {
    public var name: String
    public var genericParameters: [TSGenericParameter]
    public var decls: [TSDecl]

    public init(
        name: String,
        genericParameters: [TSGenericParameter] = [],
        decls: [TSDecl]
    ) {
        self.name = name
        self.genericParameters = genericParameters
        self.decls = decls
    }

    public func print(printer: PrettyPrinter) {
        printer.write("export interface \(name)")
        genericParameters.print(printer: printer)
        printer.writeLine(" {")
        printer.nest {
            decls.map { TSBlockItem.decl($0) }.print(printer: printer)
        }
        printer.writeLine("}")
    }
}
