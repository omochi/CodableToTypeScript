public struct ExternalReference {
    public init(
        symbols: Set<String> = [],
        code: String = ""
    ) {
        self.symbols = symbols
        self.code = code
    }

    public var symbols: Set<String>
    public var code: String

    public mutating func add(entries: [TypeMap.Entry]) {
        for entry in entries {
            symbols.formUnion(entry.symbols)
        }
    }
}
