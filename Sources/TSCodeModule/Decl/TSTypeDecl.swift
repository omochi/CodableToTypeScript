public struct TSTypeDecl: PrettyPrintable {
    public init(
        name: String,
        genericParameters: TSGenericParameters = .init(),
        type: TSType
    ) {
        self.name = name
        self.genericParameters = genericParameters
        self.type = type
    }

    public var name: String
    public var genericParameters: TSGenericParameters
    public var type: TSType

    public func print(printer: PrettyPrinter) {
        printer.write("export type \(name)")
        genericParameters.print(printer: printer)
        printer.write(" = ")
        printer.write(type)
        printer.writeLine(";")
    }
}
