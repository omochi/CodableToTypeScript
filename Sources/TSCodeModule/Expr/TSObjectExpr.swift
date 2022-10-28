public struct TSObjectExpr: PrettyPrintable {
    public var fields: [TSObjectField]

    public init(fields: [TSObjectField]) {
        self.fields = fields
    }

    public func print(printer: PrettyPrinter) {
        if fields.isEmpty {
            printer.write("{}")
            return
        }

        printer.writeLine("{")
        printer.nest {
            for (index, field) in fields.enumerated() {
                field.print(printer: printer)
                if index < fields.count - 1 {
                    printer.write(",")
                }
                printer.writeLine("")
            }
        }
        printer.write("}")
    }
}
