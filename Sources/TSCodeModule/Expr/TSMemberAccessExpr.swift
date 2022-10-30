public struct TSMemberAccessExpr: PrettyPrintable {
    public var base: TSExpr
    public var name: String

    public init(base: TSExpr, name: String) {
        self.base = base
        self.name = name
    }

    public func print(printer: PrettyPrinter) {
        base.print(printer: printer)
        printer.write(".")
        printer.write(name)
    }
}
