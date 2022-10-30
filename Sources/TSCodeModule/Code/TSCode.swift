public struct TSCode: PrettyPrintable {
    public init(
        _ items: [TSBlockItem]
    ) {
        self.items = items
    }

    public var items: [TSBlockItem]

    public func print(printer: PrettyPrinter) {
        items.print(printer: printer)
    }
}
