public protocol PrettyPrintable: CustomStringConvertible {
    func print(printer: PrettyPrinter)
}

extension PrettyPrintable {
    public var description: String {
        let printer = PrettyPrinter()
        printer.write(self)
        return printer.output
    }
}

public final class PrettyPrinter {
    private var level: Int = 0

    public private(set) var output: String = ""

    public private(set) var isStartOfLine: Bool = true

    public private(set) var line: Int = 1

    public var smallNumber: Int = 3

    public init() {}

    public func write(_ text: String) {
        indentIfStartOfLine()
        output += text
    }

    public func write<P: PrettyPrintable>(_ value: P) {
        value.print(printer: self)
    }

    public func writeUnlessStartOfLine(_ text: String) {
        if !isStartOfLine {
            write(text)
        }
    }

    public func writeLine(_ text: String) {
        if !text.isEmpty {
            write(text)
        }

        output += "\n"
        isStartOfLine = true
        line += 1
    }

    public func push() {
        level += 1
    }

    public func pop() {
        level -= 1
    }

    public func nest<R>(_ f: () throws -> R) rethrows -> R {
        push()
        defer { pop() }
        return try f()
    }

    private func indentIfStartOfLine() {
        guard isStartOfLine else { return }
        isStartOfLine = false
        output += String(repeating: "    ", count: level)
    }
}
