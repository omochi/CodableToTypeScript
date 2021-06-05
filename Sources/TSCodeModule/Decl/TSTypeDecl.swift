public struct TSTypeDecl: PrettyPrintable {
    public init(name: String, type: TSType) {
        self.name = name
        self.type = type
    }

    public var name: String
    public var type: TSType

    public func print(printer: PrettyPrinter) {
        printer.write("export type \(name) = ")
        printer.write(type)
        printer.writeLine(";")
    }
}
