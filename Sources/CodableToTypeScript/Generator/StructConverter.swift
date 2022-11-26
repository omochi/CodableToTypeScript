import SwiftTypeReader
import TypeScriptAST

struct StructConverter {
    var converter: TypeConverter

    func transpile(type: StructDecl, kind: TypeConverter.TypeKind) throws -> TSTypeDecl {
        var fields: [TSObjectType.Field] = []

        for property in type.storedProperties {
            let (type, isOptionalField) = try converter.transpileFieldTypeReference(
                type: property.interfaceType, kind: kind
            )

            fields.append(.init(
                name: property.name,
                isOptional: isOptionalField,
                type: type
            ))
        }

        return TSTypeDecl(
            modifiers: [.export],
            name: converter.transpiledName(of: type, kind: kind),
            genericParams: converter.transpileGenericParameters(type: type, kind: kind),
            type: TSObjectType(fields)
        )
    }

    func generateDecodeFunc(type: StructDecl) throws -> TSFunctionDecl {
        let builder = converter.decodeFunction()
        let decl = builder.signature(type: type)

        var fields: [TSObjectExpr.Field] = []

        for field in type.storedProperties {
            var expr: any TSExpr = TSMemberExpr(
                base: TSIdentExpr("json"),
                name: TSIdentExpr(field.name)
            )

            expr = try builder.decodeField(type: field.interfaceType, expr: expr)

            fields.append(
                .init(
                    name: field.name,
                    value: expr
                )
            )
        }

        decl.body.elements.append(
            TSReturnStmt(TSObjectExpr(fields))
        )
        
        return  decl
    }

}
