import SwiftTypeReader
import TypeScriptAST

// It provides request cache layer
struct GeneratorProxyConverter: TypeConverter {
    var generator: CodeGenerator
    var swiftType: any SType
    var impl: any TypeConverter

    func name(for target: GenerationTarget) throws -> String {
        return try impl.name(for: target)
    }

    func type(for target: GenerationTarget) throws -> any TSType {
        return try impl.type(for: target)
    }

    func fieldType(for target: GenerationTarget) throws -> (type: any TSType, isOptional: Bool) {
        return try impl.fieldType(for: target)
    }

    func valueToField(value: any TSExpr, for target: GenerationTarget) throws -> any TSExpr {
        return try impl.valueToField(value: value, for: target)
    }

    func fieldToValue(field: any TSExpr, for target: GenerationTarget) throws -> any TSExpr {
        return try impl.fieldToValue(field: field, for: target)
    }

    func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        return try impl.typeDecl(for: target)
    }

    func hasDecode() throws -> Bool {
        return try generator.context.evaluator(
            CodeGenerator.HasDecodeRequest(token: generator.requestToken, type: swiftType)
        )
    }

    func decodeName() throws -> String {
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

    func hasEncode() throws -> Bool {
        return try generator.context.evaluator(
            CodeGenerator.HasEncodeRequest(token: generator.requestToken, type: swiftType)
        )
    }

    func encodeName() throws -> String {
        return try impl.encodeName()
    }

    func boundEncode() throws -> TSExpr {
        return try impl.boundEncode()
    }

    func callEncode(entity: any TSExpr) throws -> any TSExpr {
        return try impl.callEncode(entity: entity)
    }

    func callEncodeField(entity: any TSExpr) throws -> any TSExpr {
        return try impl.callEncodeField(entity: entity)
    }

    func encodeSignature() throws -> TSFunctionDecl? {
        return try impl.encodeSignature()
    }

    func encodeDecl() throws -> TSFunctionDecl? {
        return try impl.encodeDecl()
    }

}
