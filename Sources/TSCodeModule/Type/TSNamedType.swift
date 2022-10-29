public struct TSNamedType: PrettyPrintable {
    public init(
        _ name: String,
        genericArguments: [TSGenericArgument] = []
    ) {
        self.name = name
        self.genericArguments = genericArguments
    }

    public var name: String
    public var genericArguments: [TSGenericArgument]

    public func print(printer: PrettyPrinter) {
        printer.write(name)
        genericArguments.print(printer: printer)
    }
}
