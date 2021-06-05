public struct TSDictionaryType: PrettyPrintable {
    public init(_ element: TSType) {
        self.element = element
    }

    public var element: TSType

    public func print(printer: PrettyPrinter) {
        printer.write("{ [key: string]: ")
        printer.write(element)
        printer.write("; }")
    }
}
