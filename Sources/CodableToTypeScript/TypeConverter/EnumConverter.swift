import SwiftTypeReader
import TypeScriptAST

public struct EnumConverter: TypeConverter {
    public enum EmptyEnumStrategy {
        case never
        case void

        func toKind() -> Kind {
            switch self {
            case .never: return .never
            case .void: return .void
            }
        }
    }

    public init(
        generator: CodeGenerator,
        `enum`: EnumType,
        emptyEnumStrategy: EmptyEnumStrategy = .never
    ) {
        self.generator = generator
        self.`enum` = `enum`

        let decl = `enum`.decl

        if decl.caseElements.isEmpty {
            self.kind = emptyEnumStrategy.toKind()
            return
        }

        if let raw = `enum`.rawValueType() {
            if raw.isStandardLibraryType("String") {
                self.kind = .string
                return
            }
            if raw.isStandardLibraryType(/^U?Int(8|16|32|64)?$/) {
                self.kind = .int
                return
            }
        }

        self.kind = .normal
    }

    public var generator: CodeGenerator
    public var `enum`: EnumType

    public var swiftType: any SType { `enum` }

    private var decl: EnumDecl { `enum`.decl }
    private var kind: Kind

    enum Kind {
        case never
        case void
        case string
        case int
        case normal
    }

    public func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
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
        case .void:
            var type: any TSType = TSIdentType.void
            if target == .entity {
                type = try attachTag(to: type)
            }
            return TSTypeDecl(
                modifiers: [.export],
                name: try name(for: target),
                genericParams: genericParams,
                type: type
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
        case .int:
            switch target {
            case .entity:
                let items: [any TSType] = decl.caseElements.map { (ce) in
                    TSStringLiteralType(ce.name)
                }

                return TSTypeDecl(
                    modifiers: [.export],
                    name: try name(for: target),
                    genericParams: genericParams,
                    type: TSUnionType(items)
                )
            case .json:
                let items: [any TSType] = decl.caseElements.withIntegerRawValues.map { (_, rawValue) in
                    return TSNumberLiteralType(rawValue)
                }

                return TSTypeDecl(
                    modifiers: [.export],
                    name: try name(for: target),
                    genericParams: genericParams,
                    type: TSUnionType(items)
                )
            }
        case .normal: break
        }

        let items: [any TSType] = try withErrorCollector { collect in
            decl.caseElements.compactMap { (ce) in
                collect(at: ce.name) {
                    try transpile(caseElement: ce, target: target)
                }
            }
        }

        let name = try name(for: target)
        var type: any TSType = TSUnionType(items)
        if items.count == 1 {
            // unwrap union
            type = items[0]
        }

        switch target {
        case .entity:
            type = try attachTag(to: type)
        case .json: break
        }

        return TSTypeDecl(
            modifiers: [.export],
            name: name,
            genericParams: genericParams,
            type: type
        )
    }

    private func attachTag(to type: any TSType) throws -> any TSType {
        let target = GenerationTarget.entity
        let name = try self.name(for: target)
        let tag = try generator.tagRecord(
            name: name,
            genericArgs: try self.genericParams().map {
                try TSIdentType($0.name(for: target))
            }
        )
        return TSIntersectionType(type, tag)
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

        try withErrorCollector { collect in
            for (i, value) in caseElement.associatedValues.enumerated() {
                collect(at: value.interfaceName ?? "_\(i)") {
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
            }
        }

        outerFields.append(
            .field(
                name: caseElement.name,
                type: TSObjectType(innerFields)
            )
        )

        return TSObjectType(outerFields)
    }

    public func hasDecode() throws -> Bool {
        switch kind {
        case .never: return false
        case .void: return false
        case .string: return false
        case .int: return true
        case .normal: return true
        }
    }

    public func decodeDecl() throws -> TSFunctionDecl? {
        switch kind {
        case .never, .void, .string:
            return nil
        case .int:
            return try DecodeIntFuncGen(
                converter: self,
                type: `enum`.decl
            ).generate()
        case .normal:
            return try DecodeObjFuncGen(
                generator: generator,
                converter: self,
                type: `enum`.decl
            ).generate()
        }
    }

    public func hasEncode() throws -> Bool {
        switch kind {
        case .never: return false
        case .void: return false
        case .string: return false
        case .int: return true
        case .normal: break
        }

        let map = `enum`.contextSubstitutionMap()

        var result = false

        try withErrorCollector { collect in
            for caseElement in decl.caseElements {
                for (i, value) in caseElement.associatedValues.enumerated() {
                    result = result || collect(at: "\(caseElement.name).\(value.interfaceName ?? "_\(i)")") {
                        let value = try generator.converter(
                            for: value.interfaceType.subst(map: map)
                        )
                        return try value.hasEncode()
                    } ?? false
                }
            }
        }

        return result
    }

    public func encodeDecl() throws -> TSFunctionDecl? {
        switch kind {
        case .never, .void, .string:
            return nil
        case .int:
            return try EncodeIntFuncGen(
                converter: self,
                type: `enum`.decl
            ).generate()
        case .normal:
            return try EncodeObjFuncGen(
                generator: generator,
                converter: self,
                type: `enum`.decl
            ).generate()
        }
    }
}

private struct DecodeObjFuncGen {
    var generator: CodeGenerator
    var converter: EnumConverter
    var type: EnumDecl

    private func condCode(caseElement ce: EnumCaseElementDecl) -> any TSExpr {
        return TSInfixOperatorExpr(
            TSStringLiteralExpr(ce.name),
            "in",
            TSIdentExpr.json
        )
    }

    private func decodeAssociatedValues(
        nameProvider: inout NameProvider,
        names: inout [String: String],
        caseElement: EnumCaseElementDecl,
        json: any TSExpr
    ) throws -> [TSVarDecl] {
        return try withErrorCollector { collect in
            caseElement.associatedValues.enumerated().compactMap { (i, value) in
                collect(at: value.interfaceName ?? "_\(i)") {
                    let label = value.codableLabel

                    var expr: any TSExpr = TSMemberExpr(base: json, name: label)

                    expr = try generator.converter(for: value.interfaceType)
                        .callDecodeField(json: expr)

                    let varName = nameProvider.provide(base: TSKeyword.escaped(label))
                    names[label] = varName

                    return TSVarDecl(
                        kind: .const, name: varName,
                        initializer: expr
                    )
                }
            }
        }
    }

    private func buildCaseObject(
        names: [String: String],
        caseElement: EnumCaseElementDecl
    ) throws -> TSObjectExpr {
        return TSObjectExpr(try caseElement.associatedValues.map { (value) in
            let label = value.codableLabel
            let varName = try names[label].unwrap(name: "var name")
            return TSObjectExpr.Field.named(
                name: label,
                value: TSIdentExpr(varName)
            )
        })
    }

    private func thenCode(
        nameProvider: NameProvider,
        caseElement: EnumCaseElementDecl
    ) throws -> TSBlockStmt {
        var nameProvider = nameProvider
        var block: [any ASTNode] = []

        if !caseElement.associatedValues.isEmpty {
            let j = TSVarDecl(
                kind: .const, name: "j",
                initializer: TSMemberExpr(
                    base: TSIdentExpr.json,
                    name: caseElement.name
                )
            )
            block.append(j)
            nameProvider.register(name: "j")
        }

        var names: [String: String] = [:]
        block += try decodeAssociatedValues(
            nameProvider: &nameProvider,
            names: &names,
            caseElement: caseElement,
            json: TSIdentExpr("j")
        )

        let enumValue = TSObjectExpr([
            .named(
                name: "kind",
                value: TSStringLiteralExpr(caseElement.name)
            ),
            .named(
                name: caseElement.name,
                value: try buildCaseObject(
                    names: names,
                    caseElement: caseElement
                )
            )
        ])

        block.append(TSReturnStmt(enumValue))

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

        var nameProvider = NameProvider()
        nameProvider.register(signature: decl)
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

        try withErrorCollector { collect in
            for ce in type.caseElements {
                collect(at: ce.name) {
                    let ifSt = TSIfStmt(
                        condition: condCode(caseElement: ce),
                        then: try thenCode(nameProvider: nameProvider, caseElement: ce),
                        else: nil
                    )
                    
                    appendElse(stmt: ifSt)
                }
            }
        }

        appendElse(stmt: lastElseCode())

        if let top = topStmt {
            decl.body.elements.append(top)
        }

        return decl
    }
}

private struct EncodeObjFuncGen {
    var generator: CodeGenerator
    var converter: EnumConverter
    var type: EnumDecl

    func encodeAssociatedValues(
        nameProvider: inout NameProvider,
        names: inout [String: String],
        element: EnumCaseElementDecl
    ) throws -> [TSVarDecl] {
        return try withErrorCollector { collect in
            element.associatedValues.enumerated().compactMap { (i, value) in
                collect(at: value.interfaceName ?? "_\(i)") {
                    var expr: any TSExpr = TSMemberExpr(
                        base: TSIdentExpr("e"), name: value.codableLabel
                    )

                    expr = try generator.converter(for: value.interfaceType)
                        .callEncodeField(entity: expr)

                    let varName = nameProvider.provide(base: TSKeyword.escaped(value.codableLabel))
                    names[value.codableLabel] = varName

                    return TSVarDecl(
                        kind: .const, name: varName,
                        initializer: expr
                    )
                }
            }
        }
    }

    func buildCaseObject(
        names: [String: String],
        element: EnumCaseElementDecl
    ) throws -> TSObjectExpr {
        return TSObjectExpr(try element.associatedValues.map { (value) in
            let varName = try names[value.codableLabel].unwrap(name: "var name")
            return TSObjectExpr.Field.named(
                name: value.codableLabel,
                value: TSIdentExpr(varName)
            )
        })
    }

    func caseBody(
        nameProvider: NameProvider,
        element: EnumCaseElementDecl
    ) throws -> [any ASTNode] {
        var nameProvider = nameProvider
        var code: [any ASTNode] = []

        if !element.associatedValues.isEmpty {
            let e = TSVarDecl(
                kind: .const, name: "e",
                initializer: TSMemberExpr(base: TSIdentExpr.entity, name: element.name)
            )
            code.append(e)
            nameProvider.register(name: "e")
        }

        var names: [String: String] = [:]
        code += try encodeAssociatedValues(
            nameProvider: &nameProvider,
            names: &names,
            element: element
        )

        let innerObject = try buildCaseObject(names: names, element: element)

        let outerObject = TSObjectExpr([
            .named(name: element.name, value: innerObject)
        ])

        code.append(TSReturnStmt(outerObject))
        return code
    }

    func generate() throws -> TSFunctionDecl? {
        guard let decl = try converter.encodeSignature() else { return nil }

        var nameProvider = NameProvider()
        nameProvider.register(signature: decl)

        if type.caseElements.count == 1 {
            decl.body.elements += try caseBody(
                nameProvider: nameProvider,
                element: type.caseElements[0]
            )
            return decl
        }

        let `switch` = TSSwitchStmt(
            expr: TSMemberExpr(base: TSIdentExpr.entity, name: "kind")
        )

        try withErrorCollector { collect in
            for caseElement in type.caseElements {
                collect(at: caseElement.name) {
                    `switch`.cases.append(
                        TSCaseStmt(expr: TSStringLiteralExpr(caseElement.name), elements: [
                            TSBlockStmt(
                                try caseBody(
                                    nameProvider: nameProvider,
                                    element: caseElement
                                )
                            )
                        ])
                    )
                }
            }
        }

        `switch`.cases.append(
            TSDefaultStmt(elements: [
                TSVarDecl(
                    kind: .const, name: "check", type: TSIdentType.never,
                    initializer: TSIdentExpr.entity
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

private struct DecodeIntFuncGen {
    var converter: EnumConverter
    var type: EnumDecl

    func generate() throws -> TSFunctionDecl? {
        guard let decl = try converter.decodeSignature() else { return nil }

        let `switch` = TSSwitchStmt(expr: TSIdentExpr.json)

        for (caseDecl, rawValue) in type.caseElements.withIntegerRawValues {
            `switch`.cases.append(
                TSCaseStmt(expr: TSNumberLiteralExpr(rawValue), elements: [
                    TSReturnStmt(TSStringLiteralExpr(caseDecl.name))
                ])
            )
        }

        decl.body.elements.append(`switch`)
        return decl
    }
}

private struct EncodeIntFuncGen {
    var converter: EnumConverter
    var type: EnumDecl

    func generate() throws -> TSFunctionDecl? {
        guard let decl = try converter.encodeSignature() else { return nil }

        let `switch` = TSSwitchStmt(expr: TSIdentExpr.entity)

        for (caseDecl, rawValue) in type.caseElements.withIntegerRawValues {
            `switch`.cases.append(
                TSCaseStmt(expr: TSStringLiteralExpr(caseDecl.name), elements: [
                    TSReturnStmt(TSNumberLiteralExpr(rawValue))
                ])
            )
        }

        decl.body.elements.append(`switch`)
        return decl
    }
}

extension [EnumCaseElementDecl] {
    fileprivate var withIntegerRawValues: [(EnumCaseElementDecl, Int)] {
        var currentIndex = -1
        return self.map { (ce) in
            if case .integer(let value) = ce.rawValue {
                currentIndex = value
                return (ce, currentIndex)
            } else {
                currentIndex += 1
                return (ce, currentIndex)
            }
        }
    }
}
