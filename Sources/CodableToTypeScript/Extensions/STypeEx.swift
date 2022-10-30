import SwiftTypeReader

extension SType {
    func unwrapOptional(limit: Int?) throws -> (wrapped: SType, depth: Int)? {
        var type = self
        var depth = 0
        while type.isStandardLibraryType("Optional"),
              let optional = type.struct,
              let wrapped = try optional.genericArguments()[safe: 0]
        {
            if let limit = limit,
               depth >= limit
            {
                break
            }

            type = wrapped
            depth += 1
        }

        if depth == 0 { return nil }
        return (wrapped: type, depth: depth)
    }

    func asArray() throws -> (array: StructType, element: SType)? {
        guard isStandardLibraryType("Array"),
              let array = self.struct,
              let element = try array.genericArguments()[safe: 0] else { return nil }
        return (array: array, element: element)
    }

    func asDictionary() throws -> (dictionary: StructType, value: SType)? {
        guard isStandardLibraryType("Dictionary"),
              let dict = self.struct,
              let value = try dict.genericArguments()[safe: 1] else { return nil }
        return (dictionary: dict, value: value)
    }

    func isStandardLibraryType(_ name: String) -> Bool {
        guard let type = self.regular else { return false }

        return type.location.elements == [.module(name: "Swift")] &&
        type.name == name
    }

    func hasStringRawValue() throws -> Bool {
        guard let type = self.regular else { return false }
        return try type.inheritedTypes().contains { (type) in
            type.isStandardLibraryType("String")
        }
    }
}

extension AssociatedValue {
    func label(index: Int) -> String {
        if let name = self.name {
            return name
        } else {
            return "_\(index)"
        }
    }
}
