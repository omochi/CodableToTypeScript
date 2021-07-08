public struct TSTypeDecl: PrettyPrintable {
    public init(
        name: String,
        genericParameters: [String] = [],
        type: TSType
    ) {
        self.name = name
        self.genericParameters = genericParameters
        self.type = type
    }

    public var name: String
    public var genericParameters: [String]
    public var type: TSType

    public func print(printer: PrettyPrinter) {
        var name = name
        if !genericParameters.isEmpty {
            name += "<"
            name += genericParameters.joined(separator: ", ")
            name += ">"
        }
        printer.write("export type \(name) = ")
        printer.write(type)
        printer.writeLine(";")
    }
}
