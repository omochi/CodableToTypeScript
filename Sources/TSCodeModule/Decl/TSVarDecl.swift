public struct TSVarDecl: PrettyPrintable {
    public var export: Bool
    public var kind: String
    public var name: String
    public var type: TSType?
    public var initializer: TSExpr?
    public var wantsTrailingNewline: Bool

    public init(
        export: Bool = false,
        kind: String,
        name: String,
        type: TSType? = nil,
        initializer: TSExpr? = nil,
        wantsTrailingNewline: Bool = false
    ) {
        self.export = export
        self.kind = kind
        self.name = name
        self.type = type
        self.initializer = initializer
        self.wantsTrailingNewline = wantsTrailingNewline
    }

    public func print(printer: PrettyPrinter) {
        if export {
            printer.write("export")
        }
        printer.writeUnlessStartOfLine(" ")
        printer.write("\(kind) \(name)")
        if let type = type {
            printer.write(": ")
            type.print(printer: printer)
        }
        if let initializer = initializer {
            printer.write(" = ")
            initializer.print(printer: printer)
        }
        printer.writeLine(";")
    }
}
