public struct TSNewExpr: PrettyPrintable {
    public var callee: TSExpr
    public var arguments: [TSExpr]

    public init(callee: TSExpr, arguments: [TSExpr]) {
        self.callee = callee
        self.arguments = arguments
    }

    public func print(printer: PrettyPrinter) {
        printer.write("new ")
        let call = TSCallExpr(callee: callee, arguments: arguments)
        call.print(printer: printer)
    }
}
