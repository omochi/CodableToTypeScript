public struct TSArrayType: PrettyPrintable {
    public init(_ element: TSType) {
        self.element = element
    }

    public var element: TSType

    public func print(printer: PrettyPrinter) {
        let paren: Bool
        switch element {
        case .union:
            paren = true
        default:
            paren = false
        }

        if paren {
            printer.write("(")
        }
        printer.write(element)
        if paren {
            printer.write(")")
        }
        printer.write("[]")
    }
}
