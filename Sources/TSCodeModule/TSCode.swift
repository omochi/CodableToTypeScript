public struct TSCode: CustomStringConvertible {
    public init(decls: [TSDecl]) {
        self.decls = decls
    }

    public var decls: [TSDecl]

    public var description: String {
        return decls.map { $0.description }.joined(separator: "\n")
    }
}
