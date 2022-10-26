import SwiftTypeReader
import TSCodeModule

struct TypeConverter {
    var typeMap: TypeMap

    func convert(type: SType) throws -> [TSDecl] {
        guard let type = type.regular else {
            return []
        }

        switch type {
        case .enum(let type):
            let result = try EnumConverter(converter: self).convert(type: type)
            return result.decls
        case .struct(let type):
            let result = try StructConverter(converter: self).convert(type: type)
            return result.decls
        case .protocol,
             .genericParameter:
            return []
        }
    }

    func convertNestedDecls(type: SType) throws -> TSNamespaceDecl? {
        guard let type = type.regular else {
            return nil
        }

        var nestedDecls: [TSDecl] = []
        if !type.types.isEmpty {
            for nestedType in type.types {
                nestedDecls += try self.convert(type: nestedType)
            }
        }
        if nestedDecls.isEmpty { return nil }

        return TSNamespaceDecl(
            name: type.name,
            decls: nestedDecls
        )
    }

    func transpileTypeReference(_ type: SType) throws -> TSType {
        let (unwrappedFieldType, isWrapped) = try Utils.unwrapOptional(type, limit: nil)
        if isWrapped {
            let wrapped = try transpileTypeReference(
                unwrappedFieldType
            )
            return .union([wrapped, .named("null")])
        } else if let st = type.struct,
                  st.name == "Array",
                  try st.genericArguments().count >= 1
        {
            let element = try transpileTypeReference(
                try st.genericArguments()[0]
            )
            return .array(element)
        } else if let st = type.struct,
                  st.name == "Dictionary",
                  try st.genericArguments().count >= 2
        {
            let element = try transpileTypeReference(
                try st.genericArguments()[1]
            )
            return .dictionary(element)
        }

        if let mappedName = typeMap.map(specifier: type.asSpecifier()) {
            let args = try type.genericArguments().map {
                try transpileTypeReference($0)
            }
            return .named(mappedName, genericArguments: args)
        }

        var specifier = type.asSpecifier()
        _ = specifier.removeModuleElement()

        var type: TSType = .named(try transpileTypeReferenceLastPart(type))

        for element in specifier.elements.reversed().dropFirst() {
            type = .nested(namespace: element.name, type: type)
        }

        return type
    }

    private func transpileTypeReferenceLastPart(_ type: SType) throws -> TSNamedType {
        let name: String = try {
            if let enumType = type.enum {
                return try EnumConverter.transpiledName(type: enumType)
            } else {
                return type.name
            }
        }()

        let args = try type.genericArguments().map {
            try transpileTypeReference($0)
        }

        return .init(name, genericArguments: args)
    }
}
