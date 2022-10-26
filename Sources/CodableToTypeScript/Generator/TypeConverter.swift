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
}
