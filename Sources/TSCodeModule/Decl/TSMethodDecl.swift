public struct TSMethodDecl: PrettyPrintable {
    public init(
        modifiers: [String] = [],
        name: String,
        genericParameters: [TSGenericParameter] = .init(),
        parameters: [TSFunctionParameter],
        returnType: TSType?,
        items: [TSBlockItem]? = nil
    ) {
        self.modifiers = modifiers
        self.name = name
        self.genericParameters = genericParameters
        self.parameters = parameters
        self.returnType = returnType
        self.items = items
    }

    public var modifiers: [String]
    public var name: String
    public var genericParameters: [TSGenericParameter]
    public var parameters: [TSFunctionParameter]
    public var returnType: TSType?
    public var items: [TSBlockItem]?

    public func print(printer: PrettyPrinter) {
        for modifier in modifiers {
            printer.writeUnlessStartOfLine(" ")
            printer.write(modifier)
        }
        printer.writeUnlessStartOfLine(" ")
        printer.write("\(name)")
        genericParameters.print(printer: printer)
        parameters.print(printer: printer)
        if let returnType {
            printer.write(": ")
            returnType.print(printer: printer)
        }

        if let items {
            printer.writeLine(" {")
            printer.nest {
                items.print(printer: printer)
            }
            printer.writeLine("}")
        } else {
            printer.writeLine(";")
        }
    }
}
