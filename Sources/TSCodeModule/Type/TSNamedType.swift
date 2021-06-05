import Foundation

public struct TSNamedType: PrettyPrintable {
    public init(_ name: String) {
        self.name = name
    }

    public var name: String

    public func print(printer: PrettyPrinter) {
        printer.write(name)
    }
}
