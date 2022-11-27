import SwiftTypeReader
import TypeScriptAST

struct StructConverter: TypeConverter {
    var generator: CodeGenerator
    var `struct`: StructType
    var type: any SType { `struct` }

    func hasJSONType() throws -> Bool {
        for field in `struct`.decl.storedProperties {
            if try generator.converter(for: field.interfaceType).hasJSONType() {
                return true
            }
        }
        return false
    }

    func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        switch target {
        case .entity: break
        case .json:
            guard try hasJSONType() else { return nil }
        }

        var fields: [TSObjectType.Field] = []

        for property in `struct`.decl.storedProperties {
            let (type, isOptional) = try generator.converter(for: property.interfaceType)
                .fieldType(for: target)

            fields.append(.init(
                name: property.name,
                isOptional: isOptional,
                type: type
            ))
        }

        return TSTypeDecl(
            modifiers: [.export],
            name: try name(for: target),
            genericParams: try genericParams().map { try $0.name(for: target) },
            type: TSObjectType(fields)
        )
    }

    func decodeDecl() throws -> TSFunctionDecl? {
        guard let decl = try decodeSignature() else { return nil }

        var fields: [TSObjectExpr.Field] = []

        for field in `struct`.decl.storedProperties {
            var expr: any TSExpr = TSMemberExpr(
                base: TSIdentExpr("json"),
                name: TSIdentExpr(field.name)
            )

            expr = try generator.converter(for: field.interfaceType)
                .callDecodeField(json: expr)

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

        return decl
    }
}
