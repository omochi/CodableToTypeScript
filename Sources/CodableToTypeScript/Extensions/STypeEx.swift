import SwiftTypeReader

extension TypeDecl {
    var genericParams: GenericParamList {
        if let self = self as? any GenericContext {
            return self.genericParams
        } else {
            return GenericParamList()
        }
    }

    func namePath() -> NamePath {
        return declaredInterfaceType.namePath()
    }
}

extension NominalTypeDecl {
    func isStandardLibraryType(_ name: String) -> Bool {
        return moduleContext.name == "Swift" &&
        self.name == name
    }

    func hasStringRawValue() -> Bool {
        return inheritedTypes.contains { (type) in
            type.isStandardLibraryType("String")
        }
    }
}

extension SType {
    var genericArgs: [any SType] {
        if let self = self.asNominal {
            return self.genericArgs
        } else {
            return []
        }
    }

    func namePath() -> NamePath {
        let repr = toTypeRepr(containsModule: false)

        if let ident = repr.asIdent {
            return NamePath(
                ident.elements.map { $0.name }
            )
        } else {
            return NamePath([repr.description])
        }
    }

    func unwrapOptional(limit: Int?) -> (wrapped: any SType, depth: Int)? {
        var type: any SType = self
        var depth = 0
        while type.isStandardLibraryType("Optional"),
              let optional = type.asEnum,
              let wrapped = optional.genericArgs[safe: 0]
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

    func asArray() -> (array: StructType, element: any SType)? {
        guard isStandardLibraryType("Array"),
              let array = self.asStruct,
              let element = array.genericArgs[safe: 0] else { return nil }
        return (array: array, element: element)
    }

    func asDictionary() -> (dictionary: StructType, value: any SType)? {
        guard isStandardLibraryType("Dictionary"),
              let dict = self.asStruct,
              let value = dict.genericArgs[safe: 1] else { return nil }
        return (dictionary: dict, value: value)
    }

    func isStandardLibraryType(_ name: String) -> Bool {
        guard let self = self.asNominal else { return false }
        return self.nominalTypeDecl.isStandardLibraryType(name)
    }

    func hasStringRawValue() -> Bool {
        guard let self = self.asNominal else { return false }
        return self.nominalTypeDecl.hasStringRawValue()
    }
}

extension ParamDecl {
    var index: Int {
        if let caseElement = parentContext?.asEnumCaseElement {
            return caseElement.associatedValues.firstIndex(of: self)!
        }
        fatalError()
    }

    var codableLabel: String {
        if let name = self.name {
            return name
        }
        return "_\(index)"
    }
}
