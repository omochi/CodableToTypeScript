public struct TSGenericParameter: PrettyPrintable {
    public var name: String

    public init(_ name: String) {
        self.name = name
    }

    public func print(printer: PrettyPrinter) {
        printer.write(name)
    }
}

extension [TSGenericParameter] {
    public func print(printer: PrettyPrinter) {
        if isEmpty { return }

        let isBig = count > printer.smallNumber

        printer.write("<")

        if isBig {
            printer.writeLine("")
            printer.push()
        }

        for (index, item) in enumerated() {
            item.print(printer: printer)
            if index < count - 1 {
                if isBig {
                    printer.writeLine(",")
                } else {
                    printer.write(", ")
                }
            }
        }

        if isBig {
            printer.writeLine("")
            printer.pop()
        }

        printer.write(">")
    }
}
