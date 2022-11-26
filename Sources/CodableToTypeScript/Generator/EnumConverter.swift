import SwiftTypeReader
import TypeScriptAST

struct EnumConverter {
    var converter: TypeConverter

    func transpile(type: EnumDecl, kind: TypeConverter.TypeKind) throws -> TSTypeDecl {
        let genericParams = converter.transpileGenericParameters(
            type: type, kind: kind
        )

        if type.caseElements.isEmpty {
            return TSTypeDecl(
                modifiers: [.export],
                name: converter.transpiledName(of: type, kind: kind),
                genericParams: genericParams,
                type: TSIdentType.never
            )
        } else if type.hasStringRawValue() {
            let items: [any TSType] = type.caseElements.map { (ce) in
                TSStringLiteralType(ce.name)
            }

            return TSTypeDecl(
                modifiers: [.export],
                name: converter.transpiledName(of: type, kind: kind),
                genericParams: genericParams,
                type: TSUnionType(items)
            )
        }

        let items: [any TSType] = try type.caseElements.map { (ce) in
            try transpile(caseElement: ce, kind: kind)
        }

        return TSTypeDecl(
            modifiers: [.export],
            name: converter.transpiledName(of: type, kind: kind),
            genericParams: genericParams,
            type: TSUnionType(items)
        )
    }

    private func transpile(
        caseElement: EnumCaseElementDecl,
        kind: TypeConverter.TypeKind
    ) throws -> TSObjectType {
        var outerFields: [TSObjectType.Field] = []

        switch kind {
        case .type:
            outerFields.append(
                .init(name: "kind", type: TSStringLiteralType(caseElement.name))
            )
        case .json:
            break
        }

        var innerFields: [TSObjectType.Field] = []

        for value in caseElement.associatedValues {
            let (type, isOptionalField) = try converter.transpileFieldTypeReference(
                type: value.interfaceType, kind: kind
            )

            innerFields.append(.init(
                name: value.codableLabel,
                isOptional: isOptionalField,
                type: type
            ))
        }

        outerFields.append(
            .init(
                name: caseElement.name,
                type: TSObjectType(innerFields)
            )
        )

        return TSObjectType(outerFields)
    }

    struct DecodeFunc {
        init(converter: TypeConverter, type: EnumDecl) {
            self.converter = converter
            self.type = type
            self.builder = converter.decodeFunction()
        }

        var converter: TypeConverter
        var type: EnumDecl
        var builder: DecodeFunctionBuilder

        private func condCode(caseElement ce: EnumCaseElementDecl) -> any TSExpr {
            return TSInfixOperatorExpr(
                TSStringLiteralExpr(ce.name),
                "in",
                TSIdentExpr("json")
            )
        }

        private func decodeCaseObject(
            caseElement ce: EnumCaseElementDecl,
            json: any TSExpr
        ) throws -> any TSExpr {
            var fields: [TSObjectExpr.Field] = []

            for value in ce.associatedValues {
                let label = value.codableLabel
                var expr: any TSExpr = TSMemberExpr(base: json, name: TSIdentExpr(label))

                expr = try builder.decodeField(type: value.interfaceType, expr: expr)

                let field = TSObjectExpr.Field(
                    name: label, value: expr
                )
                fields.append(field)
            }

            return TSObjectExpr(fields)
        }

        private func thenCode(caseElement ce: EnumCaseElementDecl) throws -> TSBlockStmt {
            var block: [any ASTNode] = []

            let varDecl = TSVarDecl(
                kind: .const, name: "j",
                initializer: TSMemberExpr(
                    base: TSIdentExpr("json"),
                    name: TSIdentExpr(ce.name)
                )
            )
            if !ce.associatedValues.isEmpty {
                block.append(varDecl)
            }

            let fields: [TSObjectExpr.Field] = [
                .init(
                    name: "kind",
                    value: TSStringLiteralExpr(ce.name)
                ),
                .init(
                    name: ce.name,
                    value: try decodeCaseObject(
                        caseElement: ce,
                        json: TSIdentExpr("j")
                    )
                )
            ]
            block.append(TSReturnStmt(TSObjectExpr(fields)))
            return TSBlockStmt(block)
        }

        private func lastElseCode() -> TSBlockStmt {
            return TSBlockStmt([
                TSThrowStmt(
                    TSNewExpr(
                        callee: TSIdentType.error,
                        args: [
                            TSStringLiteralExpr("unknown kind")
                        ]
                    )
                )
            ])
        }

        func generate() throws -> TSFunctionDecl {
            let decl = builder.signature(type: type)

            var topStmt: (any TSStmt)?

            func appendElse(stmt: any TSStmt) {
                if let top = topStmt?.asIf {
                    topStmt = appendElse(stmt: stmt, to: top)
                } else {
                    topStmt = stmt
                }
            }

            func appendElse(stmt: any TSStmt, to ifStmt: TSIfStmt) -> TSIfStmt {
                if let nextIf = ifStmt.else?.asIf {
                    ifStmt.else = appendElse(stmt: stmt, to: nextIf)
                } else {
                    ifStmt.else = stmt
                }

                return ifStmt
            }

            for ce in type.caseElements {
                let ifSt = TSIfStmt(
                    condition: condCode(caseElement: ce),
                    then: try thenCode(caseElement: ce),
                    else: nil
                )

                appendElse(stmt: ifSt)
            }

            appendElse(stmt: lastElseCode())

            if let top = topStmt {
                decl.body.elements.append(top)
            }

            return decl
        }
    }

}
