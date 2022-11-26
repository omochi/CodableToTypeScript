import TypeScriptAST

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

    func generate() -> TSSourceFile {
        var decls: [any ASTNode] = []

        for entry in EntryKind.allCases {
            decls.append(self.decl(entry))
        }

        return TSSourceFile(decls)
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

    func access(_ entry: EntryKind) -> any TSExpr {
        return TSIdentExpr(name(entry))
    }

    func decl(_ entry: EntryKind) -> any TSDecl {
        switch entry {
        case .identityFunction:
            let decl = TSFunctionDecl(
                modifiers: [.export],
                name: name(entry),
                genericParams: ["T"],
                params: [.init(name: "json", type: TSIdentType("T"))],
                result: TSIdentType("T"),
                body: TSBlockStmt([
                    TSReturnStmt(TSIdentExpr("json"))
                ])
            )
            return decl
        case .optionalFieldDecodeFunction:
            let decl = TSFunctionDecl(
                modifiers: [.export],
                name: name(entry),
                genericParams: ["T", "U"],
                params: [
                    .init(name: "json", type: TSUnionType([TSIdentType("T"), TSIdentType.undefined])),
                    tDecoderParameter()
                ],
                result: TSUnionType([TSIdentType("U"), TSIdentType.undefined]),
                body: TSBlockStmt([
                    TSIfStmt(
                        condition: TSInfixOperatorExpr(
                            TSIdentExpr("json"), "===", TSIdentExpr.undefined
                        ),
                        then: TSReturnStmt(TSIdentExpr.undefined)
                    ),
                    TSReturnStmt(callTDecoder())
                ])
            )
            return decl
        case .optionalDecodeFunction:
            let decl = TSFunctionDecl(
                modifiers: [.export],
                name: name(entry),
                genericParams: [.init("T"), .init("U")],
                params: [
                    .init(name: "json", type: TSUnionType([TSIdentType("T"), TSIdentType.null])),
                    tDecoderParameter()
                ],
                result: TSUnionType([TSIdentType("U"), TSIdentType.null]),
                body: TSBlockStmt([
                    TSIfStmt(
                        condition: TSInfixOperatorExpr(
                            TSIdentExpr("json"), "===", TSIdentExpr.null
                        ),
                        then: TSReturnStmt(TSIdentExpr.null)
                    ),
                    TSReturnStmt(callTDecoder())
                ])
            )
            return decl
        case .arrayDecodeFunction:
            let decl = TSFunctionDecl(
                modifiers: [.export],
                name: name(entry),
                genericParams: ["T", "U"],
                params: [
                    .init(name: "json", type: TSArrayType(TSIdentType("T"))),
                    tDecoderParameter()
                ],
                result: TSArrayType(TSIdentType("U")),
                body: TSBlockStmt([
                    TSReturnStmt(
                        TSCallExpr(
                            callee: TSMemberExpr(
                                base: TSIdentExpr("json"), name: TSIdentExpr("map")
                            ),
                            args: [
                                TSIdentExpr(tDecoderName())
                            ]
                        )
                    )
                ])
            )
            return decl
        case .dictionaryDecodeFunction:
            let decl = TSFunctionDecl(
                modifiers: [.export],
                name: name(entry),
                genericParams: ["T", "U"],
                params: [
                    .init(name: "json", type: TSDictionaryType(TSIdentType("T"))),
                    tDecoderParameter()
                ],
                result: TSDictionaryType(TSIdentType("U")),
                body: TSBlockStmt([
                    TSVarDecl(
                        kind: .const, name: "result", type: TSDictionaryType(TSIdentType("U")),
                        initializer: TSObjectExpr([])
                    ),
                    TSForInStmt(
                        kind: .const, name: "k", operator: .in, expr: TSIdentExpr("json"),
                        body: TSBlockStmt([
                            TSIfStmt(
                                condition: TSCallExpr(
                                    callee: TSMemberExpr(
                                        base: TSIdentExpr("json"), name: TSIdentExpr("hasOwnProperty")
                                    ),
                                    args: [TSIdentExpr("k")]
                                ),
                                then: TSBlockStmt([
                                    TSAssignExpr(
                                        TSSubscriptExpr(base: TSIdentExpr("result"), key: TSIdentExpr("k")),
                                        TSCallExpr(
                                            callee: TSIdentExpr(tDecoderName()),
                                            args: [
                                                TSSubscriptExpr(base: TSIdentExpr("json"), key: TSIdentExpr("k"))
                                            ]
                                        )
                                    )
                                ])
                            )
                        ])
                    ),
                    TSReturnStmt(TSIdentExpr("result"))
                ])
            )
            return decl
        }
    }

    private func tDecoderName() -> String {
        converter.decodeFunction().name(base: "T")
    }

    private func tDecoderParameter() -> TSFunctionType.Param {
        return TSFunctionType.Param(
            name: tDecoderName(),
            type: TSFunctionType(
                params: [.init(name: "json", type: TSIdentType("T"))],
                result: TSIdentType("U")
            )
        )
    }

    private func callTDecoder() -> any TSExpr {
        return TSCallExpr(
            callee: TSIdentExpr(converter.decodeFunction().name(base: "T")),
            args: [TSIdentExpr("json")]
        )
    }
}
