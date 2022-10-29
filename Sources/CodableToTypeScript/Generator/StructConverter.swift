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

        let jsonDecl = try transpile(type: type, kind: .json)
        let decodeFunc = try generateDecodeFunc(type: type)

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
            genericParameters: converter.transpileGenericParameters(type: .struct(type)),
            type: .record(TSRecordType(fields))
        )
    }

    private func generateDecodeFunc(type: StructType) throws -> TSFunctionDecl {
        let typeName = converter.transpiledName(of: .struct(type), kind: .type)
        let jsonName = converter.transpiledName(of: .struct(type), kind: .json)
        let funcName = converter.decodeFunctionName(type: .struct(type))

        let genericParameters = converter.transpileGenericParameters(type: .struct(type))
        let genericArguments: [TSGenericArgument] = genericParameters.map { (param) in
            TSGenericArgument(param.type)
        }
        let parameters: [TSFunctionParameter] = [
            .init(
                name: "json",
                type: .named(jsonName, genericArguments: genericArguments)
            )
        ]

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


        return TSFunctionDecl(
            name: funcName,
            genericParameters: genericParameters,
            parameters: parameters,
            returnType: .named(typeName, genericArguments: genericArguments),
            items: [
                .stmt(.return(.object(fields)))
            ]
        )
    }

}
