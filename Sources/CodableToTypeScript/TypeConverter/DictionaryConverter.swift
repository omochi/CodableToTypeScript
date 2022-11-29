import SwiftTypeReader
import TypeScriptAST

struct DictionaryConverter: TypeConverter {
    var generator: CodeGenerator
    var type: any SType

    private func value() throws -> any TypeConverter {
        let (_, value) = type.asDictionary()!
        return try generator.converter(for: value)
    }

    func type(for target: GenerationTarget) throws -> any TSType {
        return TSDictionaryType(
            try value().type(for: target)
        )
    }

    func hasDecode() throws -> Bool {
        return try value().hasDecode()
    }

    func decodeName() throws -> String? {
        return generator.helperLibrary().name(.dictionaryDecode)
    }

    func callDecode(json: any TSExpr) throws -> any TSExpr {
        return try `default`.callDecode(
            genericArgs: [try value().type],
            json: json
        )
    }

    func hasEncode() throws -> Bool {
        return try value().hasEncode()
    }

    func encodeName() throws -> String {
        return generator.helperLibrary().name(.dictionaryEncode)
    }

    func callEncode(entity: any TSExpr) throws -> any TSExpr {
        return try `default`.callEncode(
            genericArgs: [try value().type],
            entity: entity
        )
    }
}
