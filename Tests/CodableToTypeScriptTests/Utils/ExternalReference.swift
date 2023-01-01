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
}
