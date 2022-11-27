import SwiftTypeReader
import TypeScriptAST

// It provides request cache layer
struct GeneratorProxyConverter: TypeConverter {
    var generator: CodeGenerator
    var type: any SType
    var impl: any TypeConverter

    func name(for target: GenerationTarget) throws -> String {
        return try impl.name(for: target)
    }

    func hasJSONType() throws -> Bool {
        return try generator.context.evaluator(
            CodeGenerator.HasJSONTypeRequest(token: generator.requestToken, type: type)
        )
    }

    func type(for target: GenerationTarget) throws -> any TSType {
        return try impl.type(for: target)
    }

    func fieldType(for target: GenerationTarget) throws -> (type: any TSType, isOptional: Bool) {
        return try impl.fieldType(for: target)
    }

    func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        return try impl.typeDecl(for: target)
    }

    func decodeName() throws -> String? {
        return try impl.decodeName()
    }

    func boundDecode() throws -> TSExpr {
        return try impl.boundDecode()
    }

    func callDecode(json: any TSExpr) throws -> any TSExpr {
        return try impl.callDecode(json: json)
    }

    func callDecodeField(json: any TSExpr) throws -> any TSExpr {
        return try impl.callDecodeField(json: json)
    }

    func decodeSignature() throws -> TSFunctionDecl? {
        return try impl.decodeSignature()
    }

    func decodeDecl() throws -> TSFunctionDecl? {
        return try impl.decodeDecl()
    }
}
