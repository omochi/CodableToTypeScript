import TSCodeModule

extension TSType {
    static func orNull(_ type: TSType) -> TSType {
        return .union([type, .named(.null)])
    }

    static func orUndefined(_ type: TSType) -> TSType {
        return .union([type, .named(.undefined)])
    }
}
