public struct TSCallExpr: PrettyPrintable {
    public var callee: TSExpr
    public var arguments: [TSExpr]

    public init(callee: TSExpr, arguments: [TSExpr]) {
        self.callee = callee
        self.arguments = arguments
    }

    public func print(printer: PrettyPrinter) {
        callee.print(printer: printer)
        printer.write("(")
        let isBig = arguments.count > printer.smallNumber
        if isBig {
            printer.writeLine("")
            printer.push()
        }

        for (index, arg) in arguments.enumerated() {
            arg.print(printer: printer)

            if index < arguments.count - 1 {
                printer.write(",")
                if !isBig {
                    printer.write(" ")
                }
            }

            if isBig {
                printer.writeLine("")
            }
        }

        if isBig {
            printer.pop()
        }
        printer.write(")")
    }
}
