public struct TSFunctionParameter: PrettyPrintable {
    public var name: String
    public var type: TSType

    public init(
        name: String,
        type: TSType
    ) {
        self.name = name
        self.type = type
    }

    public func print(printer: PrettyPrinter) {
        printer.write("\(name): ")
        type.print(printer: printer)
    }
}
