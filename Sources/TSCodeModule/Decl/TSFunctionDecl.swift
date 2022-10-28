public struct TSFunctionDecl: PrettyPrintable {
    public init(
        name: String,
        genericParameters: TSGenericParameters = .init(),
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
    public var genericParameters: TSGenericParameters
    public var parameters: [TSFunctionParameter]
    public var returnType: TSType?
    public var items: [TSBlockItem]

    public func print(printer: PrettyPrinter) {
        printer.write("export function \(name)")
        genericParameters.print(printer: printer)

        printer.write("(")

        let isBig = parameters.count > printer.smallNumber

        if isBig {
            printer.writeLine("")
            printer.push()
        }

        for (index, parameter) in parameters.enumerated() {
            parameter.print(printer: printer)

            if index < parameters.count - 1 {
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

        if let returnType = returnType {
            printer.write(": ")
            returnType.print(printer: printer)
        }

        printer.writeLine(" {")
        printer.nest {
            for item in items {
                item.print(printer: printer)
            }
        }
        printer.writeLine("}")
    }
}
