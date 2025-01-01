import SwiftTypeReader
import TypeScriptAST

public struct StructConverter: TypeConverter {
    public init(generator: CodeGenerator, `struct`: StructType) {
        self.generator = generator
        self.`struct` = `struct`
    }
    
    public var generator: CodeGenerator
    public var `struct`: StructType
    public var swiftType: any SType { `struct` }

    private var decl: StructDecl { `struct`.decl }

    public func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        switch target {
        case .entity: break
        case .json:
            guard try hasJSONType() else { return nil }
        }

        var fields: [TSObjectType.Field] = []

        try withErrorCollector { collect in
            for property in decl.storedProperties.instances {
                collect(at: "\(property.name)") {
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
        let genericParams = try genericParams()

        var type: any TSType = TSObjectType(fields)
        switch target {
        case .entity:
            let tag = try generator.tagRecord(
                name: name,
                genericArgs: try genericParams.map { try $0.type(for: .entity) }
            )
            type = TSIntersectionType(type, tag)
        case .json: break
        }

        return TSTypeDecl(
            modifiers: [.export],
            name: name,
            genericParams: try genericParams.map {
                .init(try $0.name(for: target))
            },
            type: type
        )
    }
    
    public func hasDecode() throws -> Bool {
        let map = `struct`.contextSubstitutionMap()

        var result = false
        try withErrorCollector { collect in
            for p in decl.storedProperties.instances {
                result = result || collect(at: "\(p.name)") {
                    let converter = try generator.converter(for: p.interfaceType.subst(map: map))
                    return try converter.hasDecode()
                } ?? false
            }
        }
        return result
    }

    public func decodeDecl() throws -> TSFunctionDecl? {
        guard let function = try decodeSignature() else { return nil }

        var nameProvider = NameProvider()
        nameProvider.register(signature: function)
        var varNames: [String: String] = [:]

        try withErrorCollector { collect in
            for field in decl.storedProperties.instances {
                var expr: any TSExpr = TSMemberExpr(
                    base: TSIdentExpr.json,
                    name: field.name
                )
                collect(at: "\(field.name)") {
                    expr = try generator.converter(for: field.interfaceType)
                        .callDecodeField(json: expr)
                }

                let varName = nameProvider.provide(base: TSKeyword.escaped(field.name))
                varNames[field.name] = varName

                let def = TSVarDecl(
                    kind: .const, name: varName,
                    initializer: expr
                )

                function.body.elements.append(def)
            }
        }

        var fields: [TSObjectExpr.Field] = []
        for field in decl.storedProperties.instances {
            let varName = try varNames[field.name].unwrap(name: "var name")
            let expr = TSIdentExpr(varName)

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

    public func hasEncode() throws -> Bool {
        let map = `struct`.contextSubstitutionMap()

        var result = false
        try withErrorCollector { collect in
            for p in decl.storedProperties.instances {
                result = result || collect(at: "\(p.name)") {
                    let converter = try generator.converter(for: p.interfaceType.subst(map: map))
                    return try converter.hasEncode()
                } ?? false
            }
        }
        return result
    }

    public func encodeDecl() throws -> TSFunctionDecl? {
        guard let function = try encodeSignature() else { return nil }

        var nameProvider = NameProvider()
        nameProvider.register(signature: function)
        var varNames: [String: String] = [:]

        for field in decl.storedProperties.instances {
            var expr: any TSExpr = TSMemberExpr(
                base: TSIdentExpr.entity,
                name: field.name
            )

            expr = try generator.converter(for: field.interfaceType)
                .callEncodeField(entity: expr)

            let varName = nameProvider.provide(base: TSKeyword.escaped(field.name))
            varNames[field.name] = varName

            let def = TSVarDecl(
                kind: .const, name: varName,
                initializer: expr
            )

            function.body.elements.append(def)
        }

        var fields: [TSObjectExpr.Field] = []
        for field in decl.storedProperties.instances {
            let varName = try varNames[field.name].unwrap(name: "var name")
            let expr = TSIdentExpr(varName)

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
