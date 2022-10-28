struct NamePath {
    var items: [String]

    init(_ items: [String]) {
        self.items = items
    }

    func convert() -> String {
        items.joined(separator: "_")
    }
}
