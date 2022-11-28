import SwiftTypeReader
import TypeScriptAST

struct OptionalConverter: TypeConverter {
    var generator: CodeGenerator
    var type: any SType

    func wrapped(limit: Int?) throws -> any TypeConverter {
        let (wrapped, _) = type.unwrapOptional(limit: limit)!
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
        return generator.helperLibrary().name(.optionalDecodeFunction)
    }

    func callDecode(json: any TSExpr) throws -> any TSExpr {
        guard try hasDecode() else { return json }
        let decodeName = try decodeName().unwrap(name: "decode name")
        return try generator.callDecode(
            callee: TSIdentExpr(decodeName),
            genericArgs: [try wrapped(limit: nil).type],
            json: json
        )
    }

    func callDecodeField(json: any TSExpr) throws -> any TSExpr {
        guard try hasDecode() else { return json }
        let decodeName = generator.helperLibrary().name(.optionalFieldDecodeFunction)
        return try generator.callDecode(
            callee: TSIdentExpr(decodeName),
            genericArgs: [try wrapped(limit: 1).type],
            json: json
        )
    }
}
