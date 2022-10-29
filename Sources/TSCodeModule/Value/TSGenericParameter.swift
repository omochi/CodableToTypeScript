public struct TSGenericParameter: PrettyPrintable {
    public var type: TSType

    public init(_ type: TSType) {
        self.type = type
    }

    public func print(printer: PrettyPrinter) {
        type.print(printer: printer)
    }
}

extension [TSGenericParameter] {
    public func print(printer: PrettyPrinter) {
        if isEmpty { return }

        printer.write("<")
        for (index, item) in enumerated() {
            item.print(printer: printer)
            if index < count - 1 {
                printer.write(", ")
            }
        }
        printer.write(">")
    }
}
