extension String {
    static func random(length: Int) -> String {
        return StringRandom().generate(length: length)
    }
}

private struct StringRandom {
    static let chars: [Character] = [
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        "abcdefghijklmnopqrstuvwxyz",
        "0123456789"
    ].flatMap { $0 }

    func generate(length: Int) -> String {
        return String((0..<length).map { (_) in
            Self.chars.randomElement()!
        })
    }
}
