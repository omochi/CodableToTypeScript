import SwiftTypeReader

extension Optional {
    func unwrap(name: String) throws -> Wrapped {
        guard let self else {
            throw MessageError("\(name) is none")
        }
        return self
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
