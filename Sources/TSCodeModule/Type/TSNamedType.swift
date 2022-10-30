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

    public static let null = TSNamedType("null")
    public static let undefined = TSNamedType("undefined")

    public func print(printer: PrettyPrinter) {
        printer.write(name)
        genericArguments.print(printer: printer)
    }
}
