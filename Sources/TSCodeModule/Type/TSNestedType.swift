public struct TSNestedType: PrettyPrintable {
    public var namespace: String
    public var type: TSType

    public init(namespace: String, type: TSType) {
        self.namespace = namespace
        self.type = type
    }

    public func print(printer: PrettyPrinter) {
        printer.write("\(namespace).")
        type.print(printer: printer)
    }
}
