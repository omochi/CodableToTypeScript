public struct TSInterfaceDecl: PrettyPrintable {
    public var name: String
    public var genericParameters: [TSGenericParameter]
    public var extends: [TSType]?
    public var decls: [TSDecl]

    public init(
        name: String,
        genericParameters: [TSGenericParameter] = [],
        extends: [TSType]? = nil,
        decls: [TSDecl]
    ) {
        self.name = name
        self.genericParameters = genericParameters
        self.extends = extends
        self.decls = decls
    }

    public func print(printer: PrettyPrinter) {
        printer.write("export interface \(name)")
        genericParameters.print(printer: printer)
        if let extends {
            printer.write(" extends")
            extends.print(printer: printer)
        }
        if !printer.isStartOfLine {
            printer.write(" ")
        }
        printer.writeLine("{")
        printer.nest {
            decls.map { TSBlockItem.decl($0) }.print(printer: printer)
        }
        printer.writeLine("}")
    }
}
