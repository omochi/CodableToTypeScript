public struct TSTypeExpr: PrettyPrintable {
    public var type: TSType

    public init(_ type: TSType) {
        self.type = type
    }

    public func print(printer: PrettyPrinter) {
        type.print(printer: printer)
    }
}
