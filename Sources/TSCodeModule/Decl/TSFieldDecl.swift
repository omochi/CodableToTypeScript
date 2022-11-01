public struct TSFieldDecl: PrettyPrintable {
    public init(
        visibility: String? = nil,
        name: String,
        type: TSType,
        isOptional: Bool = false
    ) {
        self.visibility = visibility
        self.name = name
        self.type = type
        self.isOptional = isOptional
    }

    public var visibility: String?
    public var name: String
    public var type: TSType
    public var isOptional: Bool

    public func print(printer: PrettyPrinter) {
        if let visibility {
            printer.write(visibility)
        }
        printer.writeUnlessStartOfLine(" ")
        printer.write(name)
        if isOptional {
            printer.write("?: ")
        } else {
            printer.write(": ")
        }
        printer.write(type)
        printer.writeLine(";")
    }
}
