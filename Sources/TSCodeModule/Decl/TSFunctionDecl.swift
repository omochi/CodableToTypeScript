public struct TSFunctionDecl: PrettyPrintable {
    public init(
        export: Bool = true,
        name: String,
        genericParameters: [TSGenericParameter] = .init(),
        parameters: [TSFunctionParameter],
        returnType: TSType?,
        items: [TSBlockItem]
    ) {
        self.export = export
        self.name = name
        self.genericParameters = genericParameters
        self.parameters = parameters
        self.returnType = returnType
        self.items = items
    }

    public var export: Bool
    public var name: String
    public var genericParameters: [TSGenericParameter]
    public var parameters: [TSFunctionParameter]
    public var returnType: TSType?
    public var items: [TSBlockItem]

    public func print(printer: PrettyPrinter) {
        if export {
            printer.write("export")
        }
        printer.writeUnlessStartOfLine(" ")
        printer.write("function \(name)")
        genericParameters.print(printer: printer)
        parameters.print(printer: printer)

        if let returnType = returnType {
            printer.write(": ")
            returnType.print(printer: printer)
        }

        printer.writeLine(" {")
        printer.nest {
            items.print(printer: printer)
        }
        printer.writeLine("}")
    }
}
