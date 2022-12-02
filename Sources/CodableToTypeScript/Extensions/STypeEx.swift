import SwiftTypeReader

extension TypeDecl {
    internal func namePath() -> NamePath {
        return declaredInterfaceType.namePath()
    }

    public func walk(_ body: (any TypeDecl) throws -> Bool) rethrows {
        guard try body(self) else { return }

        guard let nominal = asNominalType else { return }

        for type in nominal.types {
            try type.walk(body)
        }
    }
}

extension NominalTypeDecl {
    public func isStandardLibraryType(_ name: String) -> Bool {
        return moduleContext.name == "Swift" &&
        self.name == name
    }

    public func isRawRepresentable() -> (any SType)? {
        for type in inheritedTypes {
            if type.isStandardLibraryType("String") { return type }
        }

        if let property = find(name: "rawValue") as? VarDecl {
            return property.interfaceType
        }

        return nil
    }
}

extension SType {
    internal var typeDecl: (any TypeDecl)? {
        switch self {
        case let type as any NominalType: return type.nominalTypeDecl
        case let param as GenericParamType: return param.decl
        default: return nil
        }
    }

    internal var genericArgs: [any SType] {
        if let self = self.asNominal {
            return self.genericArgs
        } else if let self = self.asError {
            guard let repr = self.repr as? IdentTypeRepr,
                  let element = repr.elements.last,
                  let context = self.context else
            {
                return []
            }
            return element.genericArgs.map { $0.resolve(from: context) }
        } else {
            return []
        }
    }

    internal func namePath() -> NamePath {
        let repr = toTypeRepr(containsModule: false)

        if let ident = repr.asIdent {
            return NamePath(
                ident.elements.map { $0.name }
            )
        } else {
            return NamePath([repr.description])
        }
    }

    internal func unwrapOptional(limit: Int?) -> (wrapped: any SType, depth: Int)? {
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

    internal func asArray() -> (array: StructType, element: any SType)? {
        guard isStandardLibraryType("Array"),
              let array = self.asStruct,
              let element = array.genericArgs[safe: 0] else { return nil }
        return (array: array, element: element)
    }

    internal func asDictionary() -> (dictionary: StructType, value: any SType)? {
        guard isStandardLibraryType("Dictionary"),
              let dict = self.asStruct,
              let value = dict.genericArgs[safe: 1] else { return nil }
        return (dictionary: dict, value: value)
    }

    public func isStandardLibraryType(_ name: String) -> Bool {
        guard let self = self.asNominal else { return false }
        return self.nominalTypeDecl.isStandardLibraryType(name)
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
