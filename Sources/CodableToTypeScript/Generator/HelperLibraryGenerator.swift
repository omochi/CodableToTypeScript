import TSCodeModule

struct HelperLibraryGenerator {
    enum EntryKind: CaseIterable {
        case identityFunction
        case optionalFieldDecodeFunction
        case optionalDecodeFunction
        case arrayDecodeFunction
        case dictionaryDecodeFunction
    }

    var converter: TypeConverter

    let identityFunctionName = "identity"
    let optionalFieldDecodeFunctionName = "OptionalField_decode"
    let optionalDecodeFunctionName = "Optional_decode"
    let arrayDecodeFunctionName = "Array_decode"
    let dictionaryDecodeFunctionName = "Dictionary_decode"

    func generate() -> TSCode {
        var decls: [TSDecl] = []

        for entry in EntryKind.allCases {
            decls.append(self.decl(entry))
        }

        return TSCode(decls.map { .decl($0) })
    }

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

    func decl(_ entry: EntryKind) -> TSDecl {
        switch entry {
        case .identityFunction:
            let decl = TSFunctionDecl(
                name: name(entry),
                genericParameters: [.init("T")],
                parameters: [.init(name: "json", type: .named("T"))],
                returnType: .named("T"),
                items: [
                    .stmt(.return(
                        .identifier("json")
                    ))
                ]
            )
            return .function(decl)
        case .optionalFieldDecodeFunction:
            let decl = TSFunctionDecl(
                name: name(entry),
                genericParameters: [.init("T"), .init("U")],
                parameters: [
                    .init(name: "json", type: .orUndefined(.named("T"))),
                    tDecoderParameter()
                ],
                returnType: .orUndefined(.named("U")),
                items: [
                    .stmt(.if(
                        condition: .infixOperator(.identifier("json"), "===", .identifier(.undefined)),
                        then: .return(.identifier(.undefined))
                    )),
                    .stmt(.return(callTDecoder()))
                ]
            )
            return .function(decl)
        case .optionalDecodeFunction:
            let decl = TSFunctionDecl(
                name: name(entry),
                genericParameters: [.init("T"), .init("U")],
                parameters: [
                    .init(name: "json", type: .orNull(.named("T"))),
                    tDecoderParameter()
                ],
                returnType: .orNull(.named("U")),
                items: [
                    .stmt(.if(
                        condition: .infixOperator(.identifier("json"), "===", .identifier(.null)),
                        then: .return(.identifier(.null))
                    )),
                    .stmt(.return(callTDecoder()))
                ]
            )
            return .function(decl)
        case .arrayDecodeFunction:
            let decl = TSFunctionDecl(
                name: name(entry),
                genericParameters: [.init("T"), .init("U")],
                parameters: [
                    .init(name: "json", type: .array(.named("T"))),
                    tDecoderParameter()
                ],
                returnType: .array(.named("U")),
                items: [
                    .stmt(.return(
                        .call(
                            callee: .memberAccess(
                                base: .identifier("json"), name: "map"
                            ),
                            arguments: [
                                .init(.identifier(tDecoderName()))
                            ]
                        )
                    ))
                ]
            )
            return .function(decl)
        case .dictionaryDecodeFunction:
            let decl = TSFunctionDecl(
                name: name(entry),
                genericParameters: [.init("T"), .init("U")],
                parameters: [
                    .init(name: "json", type: .dictionary(.named("T"))),
                    tDecoderParameter()
                ],
                returnType: .dictionary(.named("U")),
                items: [
                    .decl(.var(
                        kind: "const", name: "result", type: .dictionary(.named("U")),
                        initializer: .object([])
                    )),
                    .stmt(.for(
                        kind: "const", name: "k", operator: "in", expr: .identifier("json"),
                        body: .block([
                            .stmt(.if(
                                condition: .call(
                                    callee: .memberAccess(base: .identifier("json"), name: "hasOwnProperty"),
                                    arguments: [.init(.identifier("k"))]
                                ),
                                then: .block([
                                    .expr(.infixOperator(
                                        .subscript(base: .identifier("result"), key: .identifier("k")),
                                        "=",
                                        .call(
                                            callee: .identifier(tDecoderName()),
                                            arguments: [
                                                .init(.subscript(base: .identifier("json"), key: .identifier("k")))
                                            ]
                                        )
                                    ))
                                ])
                            ))
                        ])
                    )),
                    .stmt(.return(.identifier("result")))
                ]
            )
            return .function(decl)
        }
    }

    private func tDecoderName() -> String {
        converter.decodeFunction().name(base: "T")
    }

    private func tDecoderParameter() -> TSFunctionParameter {
        return TSFunctionParameter(
            name: tDecoderName(),
            type: .function(
                parameters: [.init(name: "json", type: .named("T"))],
                returnType: .named("U")
            )
        )
    }

    private func callTDecoder() -> TSExpr {
        return .call(
            callee: .identifier(converter.decodeFunction().name(base: "T")),
            arguments: [.init(.identifier("json"))]
        )
    }
}
