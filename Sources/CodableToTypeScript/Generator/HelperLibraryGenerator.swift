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
        case tagOf
        case tagRecord
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
        case .tagOf: return "TagOf"
        case .tagRecord: return "TagRecord"
        }
    }

    func access(_ entry: EntryKind) -> any TSExpr {
        return TSIdentExpr(name(entry))
    }

    func decl(_ entry: EntryKind) -> any TSDecl {
        switch entry {
        case .identity: return identityDecl()
        case .optionalFieldDecode: return optionalFieldDecodeDecl()
        case .optionalFieldEncode: return optionalFieldEncodeDecl()
        case .optionalDecode: return optionalDecodeDecl()
        case .optionalEncode: return optionalEncodeDecl()
        case .arrayDecode: return arrayDecodeDecl()
        case .arrayEncode: return arrayEncodeDecl()
        case .dictionaryDecode: return dictionaryDecodeDecl()
        case .dictionaryEncode: return dictionaryEncodeDecl()
        case .tagOf: return tagOfDecl()
        case .tagRecord: return tagRecordDecl()
        }
    }

    func identityDecl() -> TSFunctionDecl {
        return TSFunctionDecl(
            modifiers: [.export],
            name: name(.identity),
            genericParams: [.init("T")],
            params: [.init(name: "json", type: TSIdentType("T"))],
            result: TSIdentType("T"),
            body: TSBlockStmt([
                TSReturnStmt(TSIdentExpr("json"))
            ])
        )
    }

    func optionalFieldDecodeDecl() -> TSFunctionDecl {
        return TSFunctionDecl(
            modifiers: [.export],
            name: name(.optionalFieldDecode),
            genericParams: [.init("T"), .init("T_JSON")],
            params: [
                .init(name: "json", type: TSUnionType(TSIdentType("T_JSON"), TSIdentType.undefined)),
                tDecodeParameter()
            ],
            result: TSUnionType(TSIdentType("T"), TSIdentType.undefined),
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
    }

    func optionalFieldEncodeDecl() -> TSFunctionDecl {
        return TSFunctionDecl(
            modifiers: [.export],
            name: name(.optionalFieldEncode),
            genericParams: [.init("T"), .init("T_JSON")],
            params: [
                .init(name: "entity", type: TSUnionType(TSIdentType("T"), TSIdentType.undefined)),
                tEncodeParameter()
            ],
            result: TSUnionType(TSIdentType("T_JSON"), TSIdentType.undefined),
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
    }

    func optionalDecodeDecl() -> TSFunctionDecl {
        return TSFunctionDecl(
            modifiers: [.export],
            name: name(.optionalDecode),
            genericParams: [.init("T"), .init("T_JSON")],
            params: [
                .init(name: "json", type: TSUnionType(TSIdentType("T_JSON"), TSIdentType.null)),
                tDecodeParameter()
            ],
            result: TSUnionType(TSIdentType("T"), TSIdentType.null),
            body: TSBlockStmt([
                TSIfStmt(
                    condition: TSInfixOperatorExpr(
                        TSIdentExpr("json"), "===", TSNullLiteralExpr()
                    ),
                    then: TSReturnStmt(TSNullLiteralExpr())
                ),
                TSReturnStmt(callTDecode())
            ])
        )
    }

    func optionalEncodeDecl() -> TSFunctionDecl {
        return TSFunctionDecl(
            modifiers: [.export],
            name: name(.optionalEncode),
            genericParams: [.init("T"), .init("T_JSON")],
            params: [
                .init(name: "entity", type: TSUnionType(TSIdentType("T"), TSIdentType.null)),
                tEncodeParameter()
            ],
            result: TSUnionType(TSIdentType("T_JSON"), TSIdentType.null),
            body: TSBlockStmt([
                TSIfStmt(
                    condition: TSInfixOperatorExpr(
                        TSIdentExpr("entity"), "===", TSNullLiteralExpr()
                    ),
                    then: TSReturnStmt(TSNullLiteralExpr())
                ),
                TSReturnStmt(callTEncode())
            ])
        )
    }

    func arrayDecodeDecl() -> TSFunctionDecl {
        return TSFunctionDecl(
            modifiers: [.export],
            name: name(.arrayDecode),
            genericParams: [.init("T"), .init("T_JSON")],
            params: [
                .init(name: "json", type: TSArrayType(TSIdentType("T_JSON"))),
                tDecodeParameter()
            ],
            result: TSArrayType(TSIdentType("T")),
            body: TSBlockStmt([
                TSReturnStmt(
                    TSCallExpr(
                        callee: TSMemberExpr(
                            base: TSIdentExpr("json"), name: "map"
                        ),
                        args: [tDecode()]
                    )
                )
            ])
        )
    }

    func arrayEncodeDecl() -> TSFunctionDecl {
        return TSFunctionDecl(
            modifiers: [.export],
            name: name(.arrayEncode),
            genericParams: [.init("T"), .init("T_JSON")],
            params: [
                .init(name: "entity", type: TSArrayType(TSIdentType("T"))),
                tEncodeParameter()
            ],
            result: TSArrayType(TSIdentType("T_JSON")),
            body: TSBlockStmt([
                TSReturnStmt(
                    TSCallExpr(
                        callee: TSMemberExpr(
                            base: TSIdentExpr("entity"), name: "map"
                        ),
                        args: [tEncode()]
                    )
                )
            ])
        )
    }

    func dictionaryDecodeDecl() -> TSFunctionDecl {
        return TSFunctionDecl(
            modifiers: [.export],
            name: name(.dictionaryDecode),
            genericParams: [.init("T"), .init("T_JSON")],
            params: [
                .init(name: "json", type: TSObjectType.dictionary(TSIdentType("T_JSON"))),
                tDecodeParameter()
            ],
            result: TSObjectType.dictionary(TSIdentType("T")),
            body: TSBlockStmt([
                TSVarDecl(
                    kind: .const, name: "entity", type: TSObjectType.dictionary(TSIdentType("T")),
                    initializer: TSObjectExpr([])
                ),
                TSForInStmt(
                    kind: .const, name: "k", operator: .in, expr: TSIdentExpr("json"),
                    body: TSBlockStmt([
                        TSIfStmt(
                            condition: TSCallExpr(
                                callee: TSMemberExpr(
                                    base: TSIdentExpr("json"), name: "hasOwnProperty"
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
    }

    func dictionaryEncodeDecl() -> TSFunctionDecl {
        return TSFunctionDecl(
            modifiers: [.export],
            name: name(.dictionaryEncode),
            genericParams: [.init("T"), .init("T_JSON")],
            params: [
                .init(name: "entity", type: TSObjectType.dictionary(TSIdentType("T"))),
                tEncodeParameter()
            ],
            result: TSObjectType.dictionary(TSIdentType("T_JSON")),
            body: TSBlockStmt([
                TSVarDecl(
                    kind: .const, name: "json", type: TSObjectType.dictionary(TSIdentType("T_JSON")),
                    initializer: TSObjectExpr([])
                ),
                TSForInStmt(
                    kind: .const, name: "k", operator: .in, expr: TSIdentExpr("entity"),
                    body: TSBlockStmt([
                        TSIfStmt(
                            condition: TSCallExpr(
                                callee: TSMemberExpr(
                                    base: TSIdentExpr("entity"), name: "hasOwnProperty"
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
    }

    func tagOfDecl() -> TSTypeDecl {
        return TSTypeDecl(
            modifiers: [.export],
            name: name(.tagOf),
            genericParams: [.init("Type")],
            type: TSConditionalType(
                TSIdentType("Type"),
                extends: TSObjectType([
                    .field(
                        name: "$tag", isOptional: true,
                        type: TSInferType(name: "TAG")
                    )
                ]),
                true: TSIdentType("TAG"),
                false: TSIdentType.never
            )
        )
    }

    func tagRecordDecl() -> TSTypeDecl {
        return TSTypeDecl(
            modifiers: [.export],
            name: name(.tagRecord),
            genericParams: [
                .init("Name", extends: TSIdentType.string),
                .init(
                    "Args", extends: TSArrayType(TSIdentType.any),
                    default: TSTupleType([])
                )
            ],
            type: TSConditionalType(
                TSIndexedAccessType(TSIdentType("Args"), index: TSStringLiteralType("length")),
                extends: TSNumberLiteralType(0),
                true: TSObjectType([
                    .field(name: "$tag", isOptional: true, type: TSIdentType("Name"))
                ]),
                false: TSObjectType([
                    .field(name: "$tag", isOptional: true, type: TSIntersectionType(
                        TSIdentType("Name"),
                        TSMappedType(
                            "I", in: TSKeyofType(TSIdentType("Args")),
                            value: TSIdentType(name(.tagOf), genericArgs: [
                                TSIndexedAccessType(TSIdentType("Args"), index: TSIdentType("I"))
                            ])
                        )
                    ))
                ])
            )
        )
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
