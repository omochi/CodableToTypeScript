public struct TSFunctionDecl: PrettyPrintable {
    public init(
        signature: String,
        body: [String]
    ) {
        self.signature = signature
        self.body = body
    }

    public var signature: String
    public var body: [String]

    public func print(printer: PrettyPrinter) {
        printer.writeLine("export function \(signature) {")
        printer.nest {
            for line in body {
                printer.writeLine(line)
            }
        }
        printer.writeLine("}")
    }
}
