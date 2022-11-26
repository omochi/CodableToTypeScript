import TypeScriptAST

public struct TypeOwnDeclarations {
    public var type: TSTypeDecl
    public var jsonType: TSTypeDecl?
    public var decodeFunction: TSFunctionDecl?

    public init(
        type: TSTypeDecl,
        jsonType: TSTypeDecl?,
        decodeFunction: TSFunctionDecl?
    ) {
        self.type = type
        self.jsonType = jsonType
        self.decodeFunction = decodeFunction
    }

    public var decls: [any TSDecl] {
        var decls: [any TSDecl] = [
            type
        ]

        if let decl = jsonType {
            decls.append(decl)
        }

        if let decl = decodeFunction {
            decls.append(decl)
        }

        return decls
    }
}
