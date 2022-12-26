import SwiftTypeReader
import TypeScriptAST

struct StructConverter: TypeConverter {
    var generator: CodeGenerator
    var `struct`: StructType
    var swiftType: any SType { `struct` }

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

            fields.append(
                .field(
                    name: property.name,
                    isOptional: isOptional,
                    type: type
                )
            )
        }

        let name = try self.name(for: target)

        var type: any TSType = TSObjectType(fields)
        switch target {
        case .entity:
            let tag = try generator.tagRecord(
                name: name,
                genericArgs: try genericParams().map { $0.swiftType }
            )
            type = TSIntersectionType(type, tag)
        case .json: break
        }

        return TSTypeDecl(
            modifiers: [.export],
            name: name,
            genericParams: try genericParams().map {
                .init(try $0.name(for: target))
            },
            type: type
        )
    }

    func decodePresence() throws -> CodecPresence {
        let map = `struct`.contextSubstitutionMap()

        let fields = try `struct`.decl.storedProperties.map {
            try generator.converter(for: $0.interfaceType.subst(map: map))
        }

        var result: CodecPresence = .identity

        for field in fields {
            switch try field.decodePresence() {
            case .identity: break
            case .required: return .required
            case .conditional:
                result = .conditional
            }
        }

        return result
    }

    func decodeDecl() throws -> TSFunctionDecl? {
        guard let decl = try decodeSignature() else { return nil }

        var fields: [TSObjectExpr.Field] = []

        for field in `struct`.decl.storedProperties {
            var expr: any TSExpr = TSMemberExpr(
                base: TSIdentExpr("json"),
                name: field.name
            )

            expr = try generator.converter(for: field.interfaceType)
                .callDecodeField(json: expr)

            fields.append(
                .named(
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

    func encodePresence() throws -> CodecPresence {
        let map = `struct`.contextSubstitutionMap()

        let fields = try `struct`.decl.storedProperties.map {
            try generator.converter(for: $0.interfaceType.subst(map: map))
        }

        var result: CodecPresence = .identity

        for field in fields {
            switch try field.encodePresence() {
            case .identity: break
            case .required: return .required
            case .conditional:
                result = .conditional
            }
        }

        return result
    }

    func encodeDecl() throws -> TSFunctionDecl? {
        guard let decl = try encodeSignature() else { return nil }

        var fields: [TSObjectExpr.Field] = []

        for field in `struct`.decl.storedProperties {
            var expr: any TSExpr = TSMemberExpr(
                base: TSIdentExpr("entity"),
                name: field.name
            )

            expr = try generator.converter(for: field.interfaceType)
                .callEncodeField(entity: expr)

            fields.append(
                .named(
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
