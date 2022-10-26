import SwiftTypeReader
import TSCodeModule

struct StructConverter {
    struct Result {
        var typeDecl: TSTypeDecl
        var namespaceDecl: TSNamespaceDecl?

        var decls: [TSDecl] {
            var decls: [TSDecl] = [
                .typeDecl(typeDecl)
            ]

            if let d = namespaceDecl {
                decls.append(.namespaceDecl(d))
            }

            return decls
        }
    }

    init(
        converter: TypeConverter
    ) {
        self.converter = converter
    }

    private var converter: TypeConverter

    private var typeMap: TypeMap { converter.typeMap }

    func convert(type: StructType) throws -> Result {
        var fields: [TSRecordType.Field] = []

        for property in type.storedProperties {
            let fieldName = property.name
            let (type, isOptional) = try Utils.unwrapOptional(try property.type(), limit: 1)
            let fieldType = try converter.transpileTypeReference(type)

            fields.append(
                .init(name: fieldName, type: fieldType, isOptional: isOptional)
            )
        }

        let typeDecl = TSTypeDecl(
            name: type.name,
            genericParameters: type.genericParameters.map { $0.name },
            type: .record(TSRecordType(fields))
        )

        return Result(
            typeDecl: typeDecl,
            namespaceDecl: try converter.convertNestedDecls(type: .struct(type))
        )
    }

}
