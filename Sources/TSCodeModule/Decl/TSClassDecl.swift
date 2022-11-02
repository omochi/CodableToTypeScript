public struct TSClassDecl: PrettyPrintable {
    public var export: Bool
    public var name: String
    public var genericParameters: [TSGenericParameter]
    public var extends: TSType?
    public var implements: [TSType]?
    public var items: [TSBlockItem]

    public init(
        export: Bool = true,
        name: String,
        genericParameters: [TSGenericParameter] = [],
        extends: TSType? = nil,
        implements: [TSType]? = nil,
        items: [TSBlockItem]
    ) {
        self.export = export
        self.name = name
        self.genericParameters = genericParameters
        self.extends = extends
        self.implements = implements
        self.items = items
    }

    public func print(printer: PrettyPrinter) {
        if export {
            printer.write("export")
        }
        printer.writeUnlessStartOfLine(" ")
        printer.write("class \(name)")
        genericParameters.print(printer: printer)
        if let extends {
            printer.write(" extends ")
            extends.print(printer: printer)
        }
        if let implements {
            printer.write(" implements")
            implements.print(printer: printer)
        }
        printer.writeUnlessStartOfLine(" ")
        printer.writeLine("{")
        printer.with(blockScope: .class) {
            printer.nest {
                items.print(printer: printer)
            }
        }
        printer.writeLine("}")
    }
}
