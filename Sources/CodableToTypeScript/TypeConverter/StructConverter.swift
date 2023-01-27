import SwiftTypeReader
import TypeScriptAST

struct StructConverter: TypeConverter {
    var generator: CodeGenerator
    var `struct`: StructType
    var swiftType: any SType { `struct` }

    private var decl: StructDecl { `struct`.decl }

    func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        switch target {
        case .entity: break
        case .json:
            guard try hasJSONType() else { return nil }
        }

        var fields: [TSObjectType.Field] = []

        try MultipleError.collect { `do` in
            for property in decl.storedProperties {
                `do`("\(property.name)") {
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
            }
        }

        let name = try self.name(for: target)

        var type: any TSType = TSObjectType(fields)
        switch target {
        case .entity:
            let tag = try generator.tagRecord(
                name: name,
                genericArgs: try genericParams().map { try $0.type(for: .entity) }
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

        var result: [CodecPresence] = [.identity]
        try MultipleError.collect { `do` in
            for p in decl.storedProperties {
                `do`("\(p.name)") {
                    let converter = try generator.converter(for: p.interfaceType.subst(map: map))
                    result.append(try converter.decodePresence())
                }
            }
        }
        return result.max()!
    }

    func decodeDecl() throws -> TSFunctionDecl? {
        guard let function = try decodeSignature() else { return nil }

        var fields: [TSObjectExpr.Field] = []

        try MultipleError.collect { `do` in
            for field in decl.storedProperties {
                var expr: any TSExpr = TSMemberExpr(
                    base: TSIdentExpr.json,
                    name: field.name
                )
                `do`("\(field.name)") {
                    expr = try generator.converter(for: field.interfaceType)
                        .callDecodeField(json: expr)
                }

                let def = TSVarDecl(
                    kind: .const, name: field.name,
                    initializer: expr
                )

                function.body.elements.append(def)
            }
        }

        for field in decl.storedProperties {
            let expr = TSIdentExpr(field.name)

            fields.append(
                .named(
                    name: field.name,
                    value: expr
                )
            )
        }

        function.body.elements.append(
            TSReturnStmt(TSObjectExpr(fields))
        )

        return function
    }

    func encodePresence() throws -> CodecPresence {
        let map = `struct`.contextSubstitutionMap()

        var result: [CodecPresence] = [.identity]
        try MultipleError.collect { `do` in
            for p in decl.storedProperties {
                `do`("\(p.name)") {
                    let converter = try generator.converter(for: p.interfaceType.subst(map: map))
                    result.append(try converter.encodePresence())
                }
            }
        }
        return result.max()!
    }

    func encodeDecl() throws -> TSFunctionDecl? {
        guard let function = try encodeSignature() else { return nil }

        var fields: [TSObjectExpr.Field] = []

        for field in decl.storedProperties {
            var expr: any TSExpr = TSMemberExpr(
                base: TSIdentExpr.entity,
                name: field.name
            )

            expr = try generator.converter(for: field.interfaceType)
                .callEncodeField(entity: expr)

            let def = TSVarDecl(
                kind: .const, name: field.name,
                initializer: expr
            )

            function.body.elements.append(def)
        }

        for field in decl.storedProperties {
            let expr = TSIdentExpr(field.name)

            fields.append(
                .named(
                    name: field.name,
                    value: expr
                )
            )
        }

        function.body.elements.append(
            TSReturnStmt(TSObjectExpr(fields))
        )

        return function
    }

}
