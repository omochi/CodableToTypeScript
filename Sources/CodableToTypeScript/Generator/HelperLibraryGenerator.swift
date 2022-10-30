import TSCodeModule

struct HelperLibraryGenerator {
    enum EntryKind: CaseIterable {
        case identityFunction
        case optionalFieldDecodeFunction
        case optionalDecodeFunction
        case arrayDecodeFunction
        case dictionaryDecodeFunction
    }

    let identityFunctionName = "identity"
    let optionalFieldDecodeFunctionName = "OptionalField_decode"
    let optionalDecodeFunctionName = "Optional_decode"
    let arrayDecodeFunctionName = "Array_decode"
    let dictionaryDecodeFunctionName = "Dictionary_decode"

    func name(_ entry: EntryKind) -> String {
        switch entry {
        case .identityFunction: return "identity"
        case .optionalFieldDecodeFunction: return "OptionalField_decode"
        case .optionalDecodeFunction: return "Optional_decode"
        case .arrayDecodeFunction: return "Array_decode"
        case .dictionaryDecodeFunction: return "Dictionary_decode"
        }
    }

    func access(_ entry: EntryKind) -> TSExpr {
        return .identifier(name(entry))
    }
}
