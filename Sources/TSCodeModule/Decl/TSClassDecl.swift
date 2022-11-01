public struct TSClassDecl: PrettyPrintable {
    public var name: String
    public var genericParameters: [TSGenericParameter]
    public var extends: TSType?
    public var implements: [TSType]?
    public var items: [TSBlockItem]

    public init(
        name: String,
        genericParameters: [TSGenericParameter] = [],
        extends: TSType? = nil,
        implements: [TSType]? = nil,
        items: [TSBlockItem]
    ) {
        self.name = name
        self.genericParameters = genericParameters
        self.extends = extends
        self.implements = implements
        self.items = items
    }

    public func print(printer: PrettyPrinter) {
        printer.write("export class \(name)")
        genericParameters.print(printer: printer)
        if let extends {
            printer.write(" extends ")
            extends.print(printer: printer)
        }
        if let implements {
            printer.write(" implements")
            implements.print(printer: printer)
        }
        if !printer.isStartOfLine {
            printer.write(" ")
        }
        printer.writeLine("{")

        printer.nest {
            items.print(printer: printer)
        }

        printer.writeLine("}")
    }
}
