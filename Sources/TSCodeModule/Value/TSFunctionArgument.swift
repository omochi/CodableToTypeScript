public struct TSFunctionArgument: PrettyPrintable {
    public var expr: TSExpr

    public init(_ expr: TSExpr) {
        self.expr = expr
    }

    public func print(printer: PrettyPrinter) {
        expr.print(printer: printer)
    }
}

extension [TSFunctionArgument] {
    public func print(printer: PrettyPrinter) {
        printer.write("(")
        let isBig = count > printer.smallNumber
        if isBig {
            printer.writeLine("")
            printer.push()
        }

        for (index, item) in enumerated() {
            item.print(printer: printer)

            if index < count - 1 {
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
