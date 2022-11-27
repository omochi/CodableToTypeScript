import SwiftTypeReader
import TypeScriptAST

struct OldStructConverter {
    init(generator: CodeGenerator) {
        self.gen = generator
    }

    var gen: CodeGenerator

    func transpile(type: StructDecl, target: GenerationTarget) throws -> TSTypeDecl {
        var fields: [TSObjectType.Field] = []

        for property in type.storedProperties {
            let (type, isOptionalField) = try gen.transpileFieldTypeReference(
                type: property.interfaceType, target: target
            )

            fields.append(.init(
                name: property.name,
                isOptional: isOptionalField,
                type: type
            ))
        }

        return TSTypeDecl(
            modifiers: [.export],
            name: try gen.transpileTypeName(type: type, target: target),
            genericParams: try gen.transpileGenericParameters(type: type, target: target),
            type: TSObjectType(fields)
        )
    }

    func generateDecodeFunc(type: StructDecl) throws -> TSFunctionDecl {
        let builder = gen.decodeFunction()
        let decl = try builder.signature(type: type)

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
