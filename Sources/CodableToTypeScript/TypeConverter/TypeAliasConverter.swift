import SwiftTypeReader
import TypeScriptAST

struct TypeAliasConverter: TypeConverter {
    var generator: CodeGenerator
    var swiftType: any SType { typeAlias }
    var typeAlias: TypeAliasType

    private func underlying() throws -> any TypeConverter {
        try generator.converter(for: typeAlias.underlyingType)
    }

    func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        switch target {
        case .entity: break
        case .json:
            guard try hasJSONType() else { return nil }
        }
        return TSTypeDecl(
            modifiers: [.export],
            name: try name(for: target),
            genericParams: try genericParams().map { try $0.name(for: target) },
            type: try underlying().type(for: target)
        )
    }

    func decodePresence() throws -> CodecPresence {
        return try underlying().decodePresence()
    }

    func decodeDecl() throws -> TSFunctionDecl? {
        guard let decl = try decodeSignature() else { return nil }

        let expr = try underlying().callDecode(json: TSIdentExpr("json"))
        decl.body.elements.append(
            TSReturnStmt(expr)
        )

        return decl
    }

    func encodePresence() throws -> CodecPresence {
        return try underlying().encodePresence()
    }

    func encodeDecl() throws -> TSFunctionDecl? {
        guard let decl = try encodeSignature() else { return nil }

        let expr = try underlying().callEncode(entity: TSIdentExpr("entity"))
        decl.body.elements.append(
            TSReturnStmt(expr)
        )

        return decl
    }
}
