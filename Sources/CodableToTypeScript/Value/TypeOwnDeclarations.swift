import TSCodeModule

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

    public var decls: [TSDecl] {
        var decls: [TSDecl] = [
            .type(type)
        ]

        if let decl = jsonType {
            decls.append(.type(decl))
        }

        if let decl = decodeFunction {
            decls.append(.function(decl))
        }

        return decls
    }
}
