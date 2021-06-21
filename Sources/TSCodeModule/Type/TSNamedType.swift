public struct TSNamedType: PrettyPrintable {
    public init(
        _ name: String,
        genericArguments: [String]
    ) {
        self.name = name
        self.genericArguments = genericArguments
    }

    public var name: String
    public var genericArguments: [String]

    public func print(printer: PrettyPrinter) {
        var name = name
        if !genericArguments.isEmpty {
            name += "<"
            name += genericArguments.joined(separator: ", ")
            name += ">"
        }
        printer.write(name)
    }
}
