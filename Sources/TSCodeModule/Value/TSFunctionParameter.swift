public struct TSFunctionParameter: PrettyPrintable {
    public var name: String
    public var type: TSType?

    public init(
        name: String,
        type: TSType?
    ) {
        self.name = name
        self.type = type
    }

    public func print(printer: PrettyPrinter) {
        printer.write("\(name)")
        if let type = type {
            printer.write(": ")
            type.print(printer: printer)
        }
    }
}

extension [TSFunctionParameter] {
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
