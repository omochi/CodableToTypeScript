public struct TSFunctionDecl: PrettyPrintable {
    public init(
        name: String,
        genericParameters: TSGenericParameters = .init(),
        parameters: [TSFunctionParameter],
        returnType: TSType?,
        body: [String]
    ) {
        self.name = name
        self.genericParameters = genericParameters
        self.parameters = parameters
        self.returnType = returnType
        self.body = body
    }

    public var name: String
    public var genericParameters: TSGenericParameters
    public var parameters: [TSFunctionParameter]
    public var returnType: TSType?
    public var body: [String]

    public func print(printer: PrettyPrinter) {
        printer.write("export function \(name)")
        genericParameters.print(printer: printer)

        printer.write("(")

        let isLong = parameters.count > 3

        if isLong {
            printer.writeLine("")
            printer.push()
        }

        for (index, parameter) in parameters.enumerated() {
            parameter.print(printer: printer)

            if index < parameters.count - 1 {
                printer.write(",")
            }
            if isLong {
                printer.writeLine("")
            }
        }

        if isLong {
            printer.pop()
        }

        printer.write(")")

        if let returnType = returnType {
            printer.write(": ")
            returnType.print(printer: printer)
        }

        printer.writeLine(" {")
        printer.nest {
            for line in body {
                printer.writeLine(line)
            }
        }
        printer.writeLine("}")
    }
}
