public struct TSTypeDecl: PrettyPrintable {
    public init(
        export: Bool = true,
        name: String,
        genericParameters: [TSGenericParameter] = [],
        type: TSType
    ) {
        self.export = export
        self.name = name
        self.genericParameters = genericParameters
        self.type = type
    }

    public var export: Bool
    public var name: String
    public var genericParameters: [TSGenericParameter]
    public var type: TSType

    public func print(printer: PrettyPrinter) {
        if export {
            printer.write("export")
        }
        printer.writeUnlessStartOfLine(" ")
        printer.write("type \(name)")
        genericParameters.print(printer: printer)
        printer.write(" = ")
        printer.write(type)
        printer.writeLine(";")
    }
}
