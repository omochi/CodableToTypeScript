import SwiftTypeReader
import TypeScriptAST

struct EnumConverter: TypeConverter {
    init(generator: CodeGenerator, `enum`: EnumType) {
        self.generator = generator
        self.`enum` = `enum`

        let decl = `enum`.decl

        if decl.caseElements.isEmpty {
            self.kind = .never
            return
        }

        if let raw = decl.rawValueType() {
            if raw.isStandardLibraryType("String") {
                self.kind = .string
                return
            }
        }

        self.kind = .normal
    }

    var generator: CodeGenerator
    var `enum`: EnumType
    
    var swiftType: any SType { `enum` }

    private var decl: EnumDecl { `enum`.decl }
    private var kind: Kind

    enum Kind {
        case never
        case string
        case normal
    }

    func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        switch target {
        case .entity: break
        case .json:
            guard try hasJSONType() else { return nil }
        }

        let genericParams: [TSTypeParameterNode] = try self.genericParams().map {
            .init(try $0.name(for: target))
        }

        switch kind {
        case .never:
            return TSTypeDecl(
                modifiers: [.export],
                name: try name(for: target),
                genericParams: genericParams,
                type: TSIdentType.never
            )
        case .string:
            let items: [any TSType] = decl.caseElements.map { (ce) in
                TSStringLiteralType(ce.name)
            }

            return TSTypeDecl(
                modifiers: [.export],
                name: try name(for: target),
                genericParams: genericParams,
                type: TSUnionType(items)
            )
        default: break
        }

        let items: [any TSType] = try decl.caseElements.map { (ce) in
            try transpile(caseElement: ce, target: target)
        }

        let name = try name(for: target)
        var type: any TSType = TSUnionType(items)
        if items.count == 1 {
            // unwrap union
            type = items[0]
        }

        switch target {
        case .entity:
            let tag = try generator.tagRecord(
                name: name,
                genericArgs: try self.genericParams().map {
                    try TSIdentType($0.name(for: .entity))
                }
            )
            type = TSIntersectionType(type, tag)
        case .json: break
        }

        return TSTypeDecl(
            modifiers: [.export],
            name: name,
            genericParams: genericParams,
            type: type
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
                .field(
                    name: "kind", type: TSStringLiteralType(caseElement.name)
                )
            )
        case .json:
            break
        }

        var innerFields: [TSObjectType.Field] = []

        for value in caseElement.associatedValues {
            let (type, isOptional) = try generator.converter(for: value.interfaceType)
                .fieldType(for: target)

            innerFields.append(
                .field(
                    name: value.codableLabel,
                    isOptional: isOptional,
                    type: type
                )
            )
        }

        outerFields.append(
            .field(
                name: caseElement.name,
                type: TSObjectType(innerFields)
            )
        )

        return TSObjectType(outerFields)
    }

    func decodePresence() throws -> CodecPresence {
        switch kind {
        case .never: return .identity
        case .string: return .identity
        case .normal: return .required
        }
    }

    func decodeDecl() throws -> TSFunctionDecl? {
        return try DecodeFuncGen(
            generator: generator,
            converter: self,
            type: `enum`.decl
        ).generate()
    }

    func encodePresence() throws -> CodecPresence {
        switch kind {
        case .never: return .identity
        case .string: return .identity
        case .normal: break
        }

        let map = `enum`.contextSubstitutionMap()

        var result: CodecPresence = .identity

        for caseElement in decl.caseElements {
            for value in caseElement.associatedValues {
                let value = try generator.converter(
                    for: value.interfaceType.subst(map: map)
                )
                switch try value.encodePresence() {
                case .identity: break
                case .required: return .required
                case .conditional:
                    result = .conditional
                }
            }
        }

        return result
    }

    func encodeDecl() throws -> TSFunctionDecl? {
        return try EncodeFuncGen(
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
            var expr: any TSExpr = TSMemberExpr(base: json, name: label)

            expr = try generator.converter(for: value.interfaceType)
                .callDecodeField(json: expr)

            let field = TSObjectExpr.Field.named(
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
                name: ce.name
            )
        )
        if !ce.associatedValues.isEmpty {
            block.append(varDecl)
        }

        let fields: [TSObjectExpr.Field] = [
            .named(
                name: "kind",
                value: TSStringLiteralExpr(ce.name)
            ),
            .named(
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

private struct EncodeFuncGen {
    var generator: CodeGenerator
    var converter: EnumConverter
    var type: EnumDecl

    func encodeCaseValue(element: EnumCaseElementDecl) throws -> TSObjectExpr {
        var fields: [TSObjectExpr.Field] = []

        for value in element.associatedValues {
            var expr: any TSExpr = TSMemberExpr(base: TSIdentExpr("e"), name: value.codableLabel)

            expr = try generator.converter(for: value.interfaceType).callEncodeField(entity: expr)

            fields.append(.named(
                name: value.codableLabel,
                value: expr
            ))
        }

        return TSObjectExpr(fields)
    }

    func caseBody(element: EnumCaseElementDecl) throws -> [any ASTNode] {
        var code: [any ASTNode] = []

        if !element.associatedValues.isEmpty {
            let e = TSVarDecl(
                kind: .const, name: "e",
                initializer: TSMemberExpr(base: TSIdentExpr("entity"), name: element.name)
            )
            code.append(e)
        }

        let innerObject = try encodeCaseValue(element: element)

        let outerObject = TSObjectExpr([
            .named(name: element.name, value: innerObject)
        ])

        code.append(TSReturnStmt(outerObject))
        return code
    }

    func generate() throws -> TSFunctionDecl? {
        guard let decl = try converter.encodeSignature() else { return nil }

        if type.caseElements.count == 1 {
            decl.body.elements += try caseBody(element: type.caseElements[0])
            return decl
        }

        let `switch` = TSSwitchStmt(
            expr: TSMemberExpr(base: TSIdentExpr("entity"), name: "kind")
        )

        for caseElement in type.caseElements {
            `switch`.cases.append(
                TSCaseStmt(expr: TSStringLiteralExpr(caseElement.name), elements: [
                    TSBlockStmt(try caseBody(element: caseElement))
                ])
            )
        }

        `switch`.cases.append(
            TSDefaultStmt(elements: [
                TSVarDecl(
                    kind: .const, name: "check", type: TSIdentType.never,
                    initializer: TSIdentExpr("entity")
                ),
                TSThrowStmt(TSNewExpr(callee: TSIdentType.error, args: [
                    TSInfixOperatorExpr(
                        TSStringLiteralExpr("invalid case: "), "+",
                        TSIdentExpr("check")
                    )
                ]))
            ])
        )

        decl.body.elements.append(`switch`)
        return decl
    }
}
