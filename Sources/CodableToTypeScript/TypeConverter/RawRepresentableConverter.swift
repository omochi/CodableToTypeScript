import SwiftTypeReader
import TypeScriptAST

struct RawRepresentableConverter: TypeConverter {
    var generator: CodeGenerator
    var swiftType: any SType
    var rawValueType: any TypeConverter

    func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        func make(name: String, type: any TSType) throws -> TSTypeDecl {
            return TSTypeDecl(
                modifiers: [.export],
                name: name,
                genericParams: try genericParams().map { try $0.name(for: target) },
                type: type
            )
        }

        switch target {
        case .entity:
            let name = try self.name(for: target)
            let type = try rawValueType.phantomType(for: target, name: name)
            return try make(name: name, type: type)
        case .json:
            let name = try self.name(for: target)
            let type = try rawValueType.type(for: target)
            return try make(name: name, type: type)
        }
    }

    func hasDecode() throws -> Bool {
        return true
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
