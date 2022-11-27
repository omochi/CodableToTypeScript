import SwiftTypeReader
import TypeScriptAST

struct ArrayConverter: TypeConverter {
    var generator: CodeGenerator
    var type: any SType

    private func element() throws -> any TypeConverter {
        let (_, element) = type.asArray()!
        return try generator.converter(for: element)
    }

    func hasJSONType() throws -> Bool {
        return try element().hasJSONType()
    }

    func type(for target: GenerationTarget) throws -> any TSType {
        return TSArrayType(
            try element().type(for: target)
        )
    }

    func decodeName() throws -> String? {
        return generator.helperLibrary().name(.arrayDecodeFunction)
    }

    func callDecode(json: TSExpr) throws -> TSExpr {
        guard try hasJSONType() else { return json }
        let decodeName = try decodeName().unwrap(name: "decode name")
        return try generator.callDecode(
            callee: TSIdentExpr(decodeName),
            genericArgs: [try element().type],
            json: json
        )
    }
}
