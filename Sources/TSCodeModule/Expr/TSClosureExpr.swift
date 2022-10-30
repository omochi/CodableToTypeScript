public struct TSClosureExpr: PrettyPrintable {
    public var parameters: [TSFunctionParameter]
    public var returnType: TSType?
    public var body: TSStmt

    public init(
        parameters: [TSFunctionParameter],
        returnType: TSType?,
        body: TSStmt
    ) {
        self.parameters = parameters
        self.returnType = returnType
        self.body = body
    }

    public func print(printer: PrettyPrinter) {
        parameters.print(printer: printer)
        if let returnType = returnType {
            printer.write(": ")
            returnType.print(printer: printer)
        }
        printer.writeLine(" => ")
        body.print(printer: printer)
        if !printer.isStartOfLine {
            printer.writeLine("")
        }
    }
}
