import SwiftTypeReader
import TypeScriptAST

struct RawRepresentableConverter: TypeConverter {
    var generator: CodeGenerator
    var swiftType: any SType
    var rawValueType: any TypeConverter

    func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        switch target {
        case .entity: break
        case .json:
            guard try rawValueType.hasJSONType() else { return nil }
        }

        let name = try self.name(for: target)
        let type = try rawValueType.phantomType(for: target, name: name)

        return TSTypeDecl(
            modifiers: [.export],
            name: name,
            genericParams: try genericParams().map { try $0.name(for: target) },
            type: type
        )
    }

    func hasDecode() throws -> Bool {
        return try rawValueType.hasJSONType()
    }

    func decodeDecl() throws -> TSFunctionDecl? {
        guard let decl = try decodeSignature() else { return nil }

        var expr = try rawValueType.callDecode(json: TSIdentExpr("json"))
        expr = TSAsExpr(expr, try self.type(for: .entity))
        decl.body.elements.append(
            TSReturnStmt(expr)
        )

        return decl
    }

    func hasEncode() throws -> Bool {
        return try rawValueType.hasJSONType()
    }

    func encodeDecl() throws -> TSFunctionDecl? {
        guard let decl = try encodeSignature() else { return nil }

        var expr = try rawValueType.callEncode(entity: TSIdentExpr("entity"))
        expr = TSAsExpr(expr, try self.type(for: .json))
        decl.body.elements.append(
            TSReturnStmt(expr)
        )

        return decl
    }
}
