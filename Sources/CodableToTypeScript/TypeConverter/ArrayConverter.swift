import SwiftTypeReader
import TypeScriptAST

struct ArrayConverter: TypeConverter {
    var generator: CodeGenerator
    var swiftType: any SType

    private func element() throws -> any TypeConverter {
        let (_, element) = swiftType.asArray()!
        return try generator.converter(for: element)
    }
    
    func type(for target: GenerationTarget) throws -> any TSType {
        return TSArrayType(
            try element().type(for: target)
        )
    }

    func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        throw MessageError("Unsupported type: \(swiftType)")
    }

    func hasDecode() throws -> Bool {
        return try element().hasDecode()
    }

    func decodeName() throws -> String? {
        return generator.helperLibrary().name(.arrayDecode)
    }

    func callDecode(json: any TSExpr) throws -> any TSExpr {
        return try `default`.callDecode(
            genericArgs: [try element().swiftType],
            json: json
        )
    }

    func decodeDecl() throws -> TSFunctionDecl? {
        throw MessageError("Unsupported type: \(swiftType)")
    }

    func hasEncode() throws -> Bool {
        return try element().hasEncode()
    }

    func encodeName() throws -> String {
        return generator.helperLibrary().name(.arrayEncode)
    }

    func callEncode(entity: any TSExpr) throws -> any TSExpr {
        return try `default`.callEncode(
            genericArgs: [try element().swiftType],
            entity: entity
        )
    }

    func encodeDecl() throws -> TSFunctionDecl? {
        throw MessageError("Unsupported type: \(swiftType)")
    }
}
