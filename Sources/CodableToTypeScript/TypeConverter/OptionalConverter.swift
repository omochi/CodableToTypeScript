import SwiftTypeReader
import TypeScriptAST

struct OptionalConverter: TypeConverter {
    var generator: CodeGenerator
    var swiftType: any SType

    func wrapped(limit: Int?) throws -> any TypeConverter {
        let (wrapped, _) = swiftType.unwrapOptional(limit: limit)!
        return try generator.converter(for: wrapped)
    }

    func type(for target: GenerationTarget) throws -> any TSType {
        return TSUnionType([
            try wrapped(limit: nil).type(for: target),
            TSIdentType.null
        ])
    }

    func fieldType(for target: GenerationTarget) throws -> (type: any TSType, isOptional: Bool) {
        return (
            type: try wrapped(limit: 1).type(for: target),
            isOptional: true
        )
    }

    func hasDecode() throws -> Bool {
        return try wrapped(limit: nil).hasDecode()
    }

    func decodeName() throws -> String? {
        return generator.helperLibrary().name(.optionalDecode)
    }

    func callDecode(json: any TSExpr) throws -> any TSExpr {
        return try `default`.callDecode(
            genericArgs: [try wrapped(limit: nil).swiftType],
            json: json
        )
    }

    func callDecodeField(json: any TSExpr) throws -> any TSExpr {
        guard try hasDecode() else { return json }
        let decodeName = generator.helperLibrary().name(.optionalFieldDecode)
        return try generator.callDecode(
            callee: TSIdentExpr(decodeName),
            genericArgs: [try wrapped(limit: 1).swiftType],
            json: json
        )
    }

    func hasEncode() throws -> Bool {
        return try wrapped(limit: nil).hasEncode()
    }

    func encodeName() throws -> String {
        return generator.helperLibrary().name(.optionalEncode)
    }

    func callEncode(entity: any TSExpr) throws -> any TSExpr {
        return try `default`.callEncode(
            genericArgs: [try wrapped(limit: nil).swiftType],
            entity: entity
        )
    }

    func callEncodeField(entity: any TSExpr) throws -> any TSExpr {
        guard try hasEncode() else { return entity }
        let encodeName = generator.helperLibrary().name(.optionalFieldEncode)
        return try generator.callEncode(
            callee: TSIdentExpr(encodeName),
            genericArgs: [try wrapped(limit: 1).swiftType],
            entity: entity
        )
    }

}
