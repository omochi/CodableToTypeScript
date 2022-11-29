import TypeScriptAST

public struct TypeOwnDeclarations {
    public var entityType: TSTypeDecl
    public var jsonType: TSTypeDecl?
    public var decodeFunction: TSFunctionDecl?
    public var encodeFunction: TSFunctionDecl?

    public init(
        entityType: TSTypeDecl,
        jsonType: TSTypeDecl?,
        decodeFunction: TSFunctionDecl?,
        encodeFunction: TSFunctionDecl?
    ) {
        self.entityType = entityType
        self.jsonType = jsonType
        self.decodeFunction = decodeFunction
        self.encodeFunction = encodeFunction
    }

    public var decls: [any TSDecl] {
        var decls: [any TSDecl] = [
            entityType
        ]

        if let decl = jsonType {
            decls.append(decl)
        }

        if let decl = decodeFunction {
            decls.append(decl)
        }

        if let decl = encodeFunction {
            decls.append(decl)
        }

        return decls
    }
}
