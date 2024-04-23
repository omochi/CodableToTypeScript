import SwiftTypeReader
import TypeScriptAST

public struct TypeAliasConverter: TypeConverter {
    public init(generator: CodeGenerator, typeAlias: TypeAliasType) {
        self.generator = generator
        self.typeAlias = typeAlias
    }
    
    public var generator: CodeGenerator
    public var swiftType: any SType { typeAlias }
    public var typeAlias: TypeAliasType

    private func underlying() throws -> any TypeConverter {
        try generator.converter(for: typeAlias.underlyingType)
    }

    public func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        switch target {
        case .entity: break
        case .json:
            guard try hasJSONType() else { return nil }
        }
        return TSTypeDecl(
            modifiers: [.export],
            name: try name(for: target),
            genericParams: try genericParams().map {
                .init(try $0.name(for: target))
            },
            type: try underlying().type(for: target)
        )
    }

    public func hasDecode() throws -> Bool {
        return try underlying().hasDecode()
    }

    public func decodePresence() throws -> CodecPresence {
        return try underlying().decodePresence()
    }

    public func decodeDecl() throws -> TSFunctionDecl? {
        guard let decl = try decodeSignature() else { return nil }

        let expr = try underlying().callDecode(json: TSIdentExpr.json)
        decl.body.elements.append(
            TSReturnStmt(expr)
        )

        return decl
    }

    public func hasEncode() throws -> Bool {
        return try underlying().hasEncode()
    }

    public func encodePresence() throws -> CodecPresence {
        return try underlying().encodePresence()
    }

    public func encodeDecl() throws -> TSFunctionDecl? {
        guard let decl = try encodeSignature() else { return nil }

        let expr = try underlying().callEncode(entity: TSIdentExpr.entity)
        decl.body.elements.append(
            TSReturnStmt(expr)
        )

        return decl
    }
}
