public struct TSFunctionDecl: PrettyPrintable {
    public init(
        name: String,
        genericParameters: [TSGenericParameter] = .init(),
        parameters: [TSFunctionParameter],
        returnType: TSType?,
        items: [TSBlockItem]
    ) {
        self.name = name
        self.genericParameters = genericParameters
        self.parameters = parameters
        self.returnType = returnType
        self.items = items
    }

    public var name: String
    public var genericParameters: [TSGenericParameter]
    public var parameters: [TSFunctionParameter]
    public var returnType: TSType?
    public var items: [TSBlockItem]

    public func print(printer: PrettyPrinter) {
        printer.write("export function \(name)")
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
