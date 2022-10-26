public struct TSNamedType: PrettyPrintable {
    public init(
        _ name: String,
        genericArguments: [TSType] = []
    ) {
        self.name = name
        self.genericArguments = genericArguments
    }

    public var name: String
    public var genericArguments: [TSType]

    public func print(printer: PrettyPrinter) {
        var name = name
        if !genericArguments.isEmpty {
            name += "<"
            name += genericArguments.map {
                $0.description
            }.joined(separator: ", ")
            name += ">"
        }
        printer.write(name)
    }
}
