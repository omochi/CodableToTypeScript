import SwiftTypeReader

extension SType {
    func namePath() -> NamePath {
        var specifier = self.asSpecifier()
        _ = specifier.removeModuleElement()

        var parts: [String] = []
        for element in specifier.elements {
            parts.append(element.name)
        }

        return NamePath(parts)
    }

    func unwrapOptional(limit: Int?) -> (wrapped: SType, depth: Int)? {
        var type = self
        var depth = 0
        while type.isStandardLibraryType("Optional"),
              let optional = type.struct,
              let wrapped = optional.genericArguments()[safe: 0]
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

    func asArray() -> (array: StructType, element: SType)? {
        guard isStandardLibraryType("Array"),
              let array = self.struct,
              let element = array.genericArguments()[safe: 0] else { return nil }
        return (array: array, element: element)
    }

    func asDictionary() -> (dictionary: StructType, value: SType)? {
        guard isStandardLibraryType("Dictionary"),
              let dict = self.struct,
              let value = dict.genericArguments()[safe: 1] else { return nil }
        return (dictionary: dict, value: value)
    }

    func isStandardLibraryType(_ name: String) -> Bool {
        guard let type = self.regular else { return false }

        return type.location.module == "Swift" &&
        type.name == name
    }

    func hasStringRawValue() -> Bool {
        guard let type = self.regular else { return false }
        return type.inheritedTypes().contains { (type) in
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
