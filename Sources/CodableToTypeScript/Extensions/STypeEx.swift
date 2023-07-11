import SwiftTypeReader

extension TypeDecl {
    internal func namePath() -> NamePath {
        return declaredInterfaceType.namePath()
    }

    public func walkTypeDecls(_ body: (any TypeDecl) throws -> Bool) rethrows {
        guard try body(self) else { return }

        let types: [any GenericTypeDecl]
        switch self {
        case let decl as any NominalTypeDecl:
            types = decl.types
        case let decl as Module:
            types = decl.types
        default:
            return
        }

        for type in types {
            try type.walkTypeDecls(body)
        }
    }

    public var typeName: String? {
        switch self {
        case let decl as any NominalTypeDecl: return decl.name
        case let decl as TypeAliasDecl: return decl.name
        case let decl as Module: return decl.name
        default: return nil
        }
    }
}

extension NominalTypeDecl {
    public func isStandardLibraryType(_ name: String) -> Bool {
        return moduleContext.name == "Swift" &&
        self.name == name
    }

    public func isStandardLibraryType(_ regex: some RegexComponent) -> Bool {
        return moduleContext.name == "Swift" &&
        !self.name.matches(of: regex).isEmpty
    }

    public func rawValueType() -> (any SType)? {
        for type in inheritedTypes {
            if type.isStandardLibraryType("String") { return type }
            if type.isStandardLibraryType(/U?Int(8|16|32|64)?/) { return type }
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
        case let type as GenericParamType: return type.decl
        case let type as TypeAliasType: return type.decl
        default: return nil
        }
    }

    internal var genericArgs: [any SType] {
        switch self {
        case let type as any NominalType: return type.genericArgs
        case let type as TypeAliasType: return type.genericArgs
        case let type as ErrorType:
            guard let repr = type.repr as? IdentTypeRepr,
                  let element = repr.elements.last,
                  let context = type.context else
            {
                return []
            }
            return element.genericArgs.map { $0.resolve(from: context) }
        default: return []
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

    public func isStandardLibraryType(_ regex: some RegexComponent) -> Bool {
        guard let self = self.asNominal else { return false }
        return self.nominalTypeDecl.isStandardLibraryType(regex)
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
