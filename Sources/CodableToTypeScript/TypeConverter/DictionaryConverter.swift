import SwiftTypeReader
import TypeScriptAST

struct DictionaryConverter: TypeConverter {
    var generator: CodeGenerator
    var type: any SType

    private func value() throws -> any TypeConverter {
        let (_, value) = type.asDictionary()!
        return try generator.converter(for: value)
    }

    func hasJSONType() throws -> Bool {
        return try value().hasJSONType()
    }

    func type(for target: GenerationTarget) throws -> any TSType {
        return TSDictionaryType(
            try value().type(for: target)
        )
    }

    func decodeName() throws -> String? {
        return generator.helperLibrary().name(.dictionaryDecodeFunction)
    }

    func callDecode(json: TSExpr) throws -> TSExpr {
        guard try hasJSONType() else { return json }
        let decodeName = try decodeName().unwrap(name: "decode name")
        return try generator.callDecode(
            callee: TSIdentExpr(decodeName),
            genericArgs: [try value().type],
            json: json
        )
    }
}
