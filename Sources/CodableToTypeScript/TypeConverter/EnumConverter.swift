import SwiftTypeReader
import TypeScriptAST

struct EnumConverter: TypeConverter {
    var generator: CodeGenerator
    var `enum`: EnumType
    
    var type: any SType { `enum` }

    func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        switch target {
        case .entity: break
        case .json:
            guard try hasJSONType() else { return nil }
        }

        let genericParams = try self.genericParams().map { try $0.name(for: target) }

        if `enum`.decl.caseElements.isEmpty {
            return TSTypeDecl(
                modifiers: [.export],
                name: try name(for: target),
                genericParams: genericParams,
                type: TSIdentType.never
            )
        } else if `enum`.decl.hasStringRawValue() {
            let items: [any TSType] = `enum`.decl.caseElements.map { (ce) in
                TSStringLiteralType(ce.name)
            }

            return TSTypeDecl(
                modifiers: [.export],
                name: try name(for: target),
                genericParams: genericParams,
                type: TSUnionType(items)
            )
        }

        let items: [any TSType] = try `enum`.decl.caseElements.map { (ce) in
            try transpile(caseElement: ce, target: target)
        }

        return TSTypeDecl(
            modifiers: [.export],
            name: try name(for: target),
            genericParams: genericParams,
            type: TSUnionType(items)
        )
    }

    private func transpile(
        caseElement: EnumCaseElementDecl,
        target: GenerationTarget
    ) throws -> TSObjectType {
        var outerFields: [TSObjectType.Field] = []

        switch target {
        case .entity:
            outerFields.append(
                .init(name: "kind", type: TSStringLiteralType(caseElement.name))
            )
        case .json:
            break
        }

        var innerFields: [TSObjectType.Field] = []

        for value in caseElement.associatedValues {
            let (type, isOptional) = try generator.converter(for: value.interfaceType)
                .fieldType(for: target)

            innerFields.append(.init(
                name: value.codableLabel,
                isOptional: isOptional,
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

    func hasDecode() throws -> Bool {
        if `enum`.decl.caseElements.isEmpty {
            return false
        } else if `enum`.hasStringRawValue() {
            return false
        } else {
            return true
        }
    }

    func decodeDecl() throws -> TSFunctionDecl? {
        return try DecodeFuncGen(
            generator: generator,
            converter: self,
            type: `enum`.decl
        ).generate()
    }
}

private struct DecodeFuncGen {
    var generator: CodeGenerator
    var converter: EnumConverter
    var type: EnumDecl

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

            expr = try generator.converter(for: value.interfaceType)
                .callDecodeField(json: expr)

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

    func generate() throws -> TSFunctionDecl? {
        guard let decl = try converter.decodeSignature() else { return nil }

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
