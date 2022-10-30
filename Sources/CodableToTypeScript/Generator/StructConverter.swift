import SwiftTypeReader
import TSCodeModule

struct StructConverter {
    init(
        converter: TypeConverter
    ) {
        self.converter = converter
    }

    private var converter: TypeConverter

    private var typeMap: TypeMap { converter.typeMap }

    func convert(type: StructType) throws -> TypeConverter.TypeResult {
        let typeDecl = try transpile(type: type, kind: .type)

        var jsonDecl: TSTypeDecl?
        var decodeFunc: TSFunctionDecl?

        if try !converter.hasEmptyDecoder(type: .struct(type)) {
            jsonDecl = try transpile(type: type, kind: .json)
            decodeFunc = try generateDecodeFunc(type: type)
        }

        return .init(
            typeDecl: typeDecl,
            jsonDecl: jsonDecl,
            decodeFunc: decodeFunc,
            nestedTypeDecls: try converter.convertNestedTypeDecls(type: .struct(type))
        )
    }

    private func transpile(type: StructType, kind: TypeConverter.TypeKind) throws -> TSTypeDecl {
        var fields: [TSRecordType.Field] = []

        for property in type.storedProperties {
            let (type, isOptionalField) = try converter.transpileFieldTypeReference(
                type: try property.type(), kind: kind
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

    private func generateDecodeFunc(type: StructType) throws -> TSFunctionDecl {
        var decl = converter.decodeFunctionSignature(type: .struct(type))

        var fields: [TSObjectField] = []

        for field in type.storedProperties {
            var expr: TSExpr = .memberAccess(
                base: .identifier("json"),
                name: field.name
            )

            expr = try converter.generateFieldDecodeExpression(
                type: try field.type(), expr: expr
            )

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
