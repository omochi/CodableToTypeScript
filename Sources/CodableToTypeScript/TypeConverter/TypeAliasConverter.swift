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
        return true
    }

    public func usesIdentityDecode() throws -> Bool {
        let underlying = try underlying()
        let needsFallbackCast = try underlying.hasJSONType() && !underlying.hasDecode()
        return try underlying.usesIdentityDecode() && !needsFallbackCast
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
        return true
    }

    public func usesIdentityEncode() throws -> Bool {
        let underlying = try underlying()
        let needsFallbackCast = try underlying.hasJSONType() && !underlying.hasEncode()
        return try underlying.usesIdentityEncode() && !needsFallbackCast
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
