public struct TSClosureExpr: PrettyPrintable {
    public var parameters: [TSFunctionParameter]
    public var returnType: TSType?
    public var items: [TSBlockItem]

    public init(
        parameters: [TSFunctionParameter],
        returnType: TSType?,
        items: [TSBlockItem]
    ) {
        self.parameters = parameters
        self.returnType = returnType
        self.items = items
    }

    public func print(printer: PrettyPrinter) {
        parameters.print(printer: printer)
        if let returnType = returnType {
            printer.write(": ")
            returnType.print(printer: printer)
        }
        printer.writeLine(" => {")
        printer.nest {
            items.print(printer: printer)
        }
        printer.write("}")
    }
}
