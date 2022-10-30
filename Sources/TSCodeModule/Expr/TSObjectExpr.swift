public struct TSObjectExpr: PrettyPrintable {
    public var fields: [TSObjectField]

    public init(_ fields: [TSObjectField]) {
        self.fields = fields
    }

    public func print(printer: PrettyPrinter) {
        if fields.isEmpty {
            printer.write("{}")
            return
        }

        printer.writeLine("{")
        printer.nest {
            fields.print(printer: printer)
        }
        printer.write("}")
    }
}
