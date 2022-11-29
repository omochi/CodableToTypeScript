import TypeScriptAST

struct HelperLibraryGenerator {
    enum EntryKind: CaseIterable {
        case identity
        case optionalFieldDecode
        case optionalFieldEncode
        case optionalDecode
        case optionalEncode
        case arrayDecode
        case arrayEncode
        case dictionaryDecode
        case dictionaryEncode
    }

    var generator: CodeGenerator

    func generate() -> TSSourceFile {
        var decls: [any ASTNode] = []

        for entry in EntryKind.allCases {
            decls.append(self.decl(entry))
        }

        return TSSourceFile(decls)
    }

    func name(_ entry: EntryKind) -> String {
        switch entry {
        case .identity: return "identity"
        case .optionalFieldDecode: return "OptionalField_decode"
        case .optionalFieldEncode: return "OptionalField_encode"
        case .optionalDecode: return "Optional_decode"
        case .optionalEncode: return "Optional_encode"
        case .arrayDecode: return "Array_decode"
        case .arrayEncode: return "Array_encode"
        case .dictionaryDecode: return "Dictionary_decode"
        case .dictionaryEncode: return "Dictionary_encode"
        }
    }

    func access(_ entry: EntryKind) -> any TSExpr {
        return TSIdentExpr(name(entry))
    }

    func decl(_ entry: EntryKind) -> any TSDecl {
        switch entry {
        case .identity:
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
        case .optionalFieldDecode:
            let decl = TSFunctionDecl(
                modifiers: [.export],
                name: name(entry),
                genericParams: ["T", "T_JSON"],
                params: [
                    .init(name: "json", type: TSUnionType([TSIdentType("T_JSON"), TSIdentType.undefined])),
                    tDecodeParameter()
                ],
                result: TSUnionType([TSIdentType("T"), TSIdentType.undefined]),
                body: TSBlockStmt([
                    TSIfStmt(
                        condition: TSInfixOperatorExpr(
                            TSIdentExpr("json"), "===", TSIdentExpr.undefined
                        ),
                        then: TSReturnStmt(TSIdentExpr.undefined)
                    ),
                    TSReturnStmt(callTDecode())
                ])
            )
            return decl
        case .optionalFieldEncode:
            let decl = TSFunctionDecl(
                modifiers: [.export],
                name: name(entry),
                genericParams: ["T", "T_JSON"],
                params: [
                    .init(name: "entity", type: TSUnionType([TSIdentType("T"), TSIdentType.undefined])),
                    tEncodeParameter()
                ],
                result: TSUnionType([TSIdentType("T_JSON"), TSIdentType.undefined]),
                body: TSBlockStmt([
                    TSIfStmt(
                        condition: TSInfixOperatorExpr(
                            TSIdentExpr("entity"), "===", TSIdentExpr.undefined
                        ),
                        then: TSReturnStmt(TSIdentExpr.undefined)
                    ),
                    TSReturnStmt(callTEncode())
                ])
            )
            return decl
        case .optionalDecode:
            let decl = TSFunctionDecl(
                modifiers: [.export],
                name: name(entry),
                genericParams: [.init("T"), .init("T_JSON")],
                params: [
                    .init(name: "json", type: TSUnionType([TSIdentType("T_JSON"), TSIdentType.null])),
                    tDecodeParameter()
                ],
                result: TSUnionType([TSIdentType("T"), TSIdentType.null]),
                body: TSBlockStmt([
                    TSIfStmt(
                        condition: TSInfixOperatorExpr(
                            TSIdentExpr("json"), "===", TSIdentExpr.null
                        ),
                        then: TSReturnStmt(TSIdentExpr.null)
                    ),
                    TSReturnStmt(callTDecode())
                ])
            )
            return decl
        case .optionalEncode:
            let decl = TSFunctionDecl(
                modifiers: [.export],
                name: name(entry),
                genericParams: [.init("T"), .init("T_JSON")],
                params: [
                    .init(name: "entity", type: TSUnionType([TSIdentType("T"), TSIdentType.null])),
                    tEncodeParameter()
                ],
                result: TSUnionType([TSIdentType("T_JSON"), TSIdentType.null]),
                body: TSBlockStmt([
                    TSIfStmt(
                        condition: TSInfixOperatorExpr(
                            TSIdentExpr("entity"), "===", TSIdentExpr.null
                        ),
                        then: TSReturnStmt(TSIdentExpr.null)
                    ),
                    TSReturnStmt(callTEncode())
                ])
            )
            return decl
        case .arrayDecode:
            let decl = TSFunctionDecl(
                modifiers: [.export],
                name: name(entry),
                genericParams: ["T", "T_JSON"],
                params: [
                    .init(name: "json", type: TSArrayType(TSIdentType("T_JSON"))),
                    tDecodeParameter()
                ],
                result: TSArrayType(TSIdentType("T")),
                body: TSBlockStmt([
                    TSReturnStmt(
                        TSCallExpr(
                            callee: TSMemberExpr(
                                base: TSIdentExpr("json"), name: TSIdentExpr("map")
                            ),
                            args: [tDecode()]
                        )
                    )
                ])
            )
            return decl
        case .arrayEncode:
            let decl = TSFunctionDecl(
                modifiers: [.export],
                name: name(entry),
                genericParams: ["T", "T_JSON"],
                params: [
                    .init(name: "entity", type: TSArrayType(TSIdentType("T"))),
                    tEncodeParameter()
                ],
                result: TSArrayType(TSIdentType("T_JSON")),
                body: TSBlockStmt([
                    TSReturnStmt(
                        TSCallExpr(
                            callee: TSMemberExpr(
                                base: TSIdentExpr("entity"), name: TSIdentExpr("map")
                            ),
                            args: [tEncode()]
                        )
                    )
                ])
            )
            return decl
        case .dictionaryDecode:
            let decl = TSFunctionDecl(
                modifiers: [.export],
                name: name(entry),
                genericParams: ["T", "T_JSON"],
                params: [
                    .init(name: "json", type: TSDictionaryType(TSIdentType("T_JSON"))),
                    tDecodeParameter()
                ],
                result: TSDictionaryType(TSIdentType("T")),
                body: TSBlockStmt([
                    TSVarDecl(
                        kind: .const, name: "entity", type: TSDictionaryType(TSIdentType("T")),
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
                                        TSSubscriptExpr(base: TSIdentExpr("entity"), key: TSIdentExpr("k")),
                                        TSCallExpr(
                                            callee: tDecode(),
                                            args: [
                                                TSSubscriptExpr(base: TSIdentExpr("json"), key: TSIdentExpr("k"))
                                            ]
                                        )
                                    )
                                ])
                            )
                        ])
                    ),
                    TSReturnStmt(TSIdentExpr("entity"))
                ])
            )
            return decl
        case .dictionaryEncode:
            let decl = TSFunctionDecl(
                modifiers: [.export],
                name: name(entry),
                genericParams: ["T", "T_JSON"],
                params: [
                    .init(name: "entity", type: TSDictionaryType(TSIdentType("T"))),
                    tEncodeParameter()
                ],
                result: TSDictionaryType(TSIdentType("T_JSON")),
                body: TSBlockStmt([
                    TSVarDecl(
                        kind: .const, name: "json", type: TSDictionaryType(TSIdentType("T_JSON")),
                        initializer: TSObjectExpr([])
                    ),
                    TSForInStmt(
                        kind: .const, name: "k", operator: .in, expr: TSIdentExpr("entity"),
                        body: TSBlockStmt([
                            TSIfStmt(
                                condition: TSCallExpr(
                                    callee: TSMemberExpr(
                                        base: TSIdentExpr("entity"), name: TSIdentExpr("hasOwnProperty")
                                    ),
                                    args: [TSIdentExpr("k")]
                                ),
                                then: TSBlockStmt([
                                    TSAssignExpr(
                                        TSSubscriptExpr(base: TSIdentExpr("json"), key: TSIdentExpr("k")),
                                        TSCallExpr(
                                            callee: tEncode(),
                                            args: [
                                                TSSubscriptExpr(base: TSIdentExpr("entity"), key: TSIdentExpr("k"))
                                            ]
                                        )
                                    )
                                ])
                            )
                        ])
                    ),
                    TSReturnStmt(TSIdentExpr("json"))
                ])
            )
            return decl
        }
    }

    private func tDecode() -> TSIdentExpr {
        return TSIdentExpr(
            DefaultTypeConverter.decodeName(entityName: "T")
        )
    }

    private func tDecodeParameter() -> TSFunctionType.Param {
        return TSFunctionType.Param(
            name: tDecode().name,
            type: TSFunctionType(
                params: [.init(name: "json", type: TSIdentType("T_JSON"))],
                result: TSIdentType("T")
            )
        )
    }

    private func callTDecode() -> any TSExpr {
        return TSCallExpr(
            callee: tDecode(),
            args: [TSIdentExpr("json")]
        )
    }

    private func tEncode() -> TSIdentExpr {
        return TSIdentExpr(
            DefaultTypeConverter.encodeName(entityName: "T")
        )
    }

    private func tEncodeParameter() -> TSFunctionType.Param {
        return TSFunctionType.Param(
            name: tEncode().name,
            type: TSFunctionType(
                params: [.init(name: "entity", type: TSIdentType("T"))],
                result: TSIdentType("T_JSON")
            )
        )
    }

    private func callTEncode() -> any TSExpr {
        return TSCallExpr(
            callee: tEncode(),
            args: [TSIdentExpr("entity")]
        )
    }
}
