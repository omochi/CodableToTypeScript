public struct TSFunctionType: PrettyPrintable {
    public var parameters: [TSFunctionParameter]
    public var returnType: TSType

    public init(
        parameters: [TSFunctionParameter],
        returnType: TSType
    ) {
        self.parameters = parameters
        self.returnType = returnType
    }

    public func print(printer: PrettyPrinter) {
        parameters.print(printer: printer)
        printer.write(" => ")
        returnType.print(printer: printer)
    }
}
