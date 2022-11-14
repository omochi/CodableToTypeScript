import SwiftTypeReader
import TSCodeModule

struct StructConverter {
    var converter: TypeConverter

    func transpile(type: StructType, kind: TypeConverter.TypeKind) throws -> TSTypeDecl {
        var fields: [TSRecordType.Field] = []

        for property in type.storedProperties {
            let (type, isOptionalField) = try converter.transpileFieldTypeReference(
                type: property.type(), kind: kind
            )

            fields.append(.init(
                name: property.name,
                type: type,
                isOptional: isOptionalField
            ))
        }

        return TSTypeDecl(
            name: converter.transpiledName(of: .struct(type), kind: kind),
            genericParameters: converter.transpileGenericParameters(type: .struct(type), kind: kind),
            type: .record(TSRecordType(fields))
        )
    }

    func generateDecodeFunc(type: StructType) throws -> TSFunctionDecl {
        let builder = converter.decodeFunction()
        var decl = builder.signature(type: .struct(type))

        var fields: [TSObjectField] = []

        for field in type.storedProperties {
            var expr: TSExpr = .memberAccess(
                base: .identifier("json"),
                name: field.name
            )

            expr = try builder.decodeField(type: field.type(), expr: expr)

            fields.append(
                .init(
                    name: .identifier(field.name),
                    value: expr
                )
            )
        }

        decl.items = [
            .stmt(.return(.object(fields)))
        ]

        return  decl
    }

}
