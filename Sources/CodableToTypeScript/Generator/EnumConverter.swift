import SwiftTypeReader
import TSCodeModule

struct EnumConverter {
    init(converter: TypeConverter) {
        self.converter = converter
    }

    private var converter: TypeConverter
    private var typeMap: TypeMap { converter.typeMap }

    func convert(type: EnumType) throws -> TypeConverter.TypeResult {
        let typeDecl = try transpile(type: type, kind: .type)

        let jsonDecl = try transpile(type: type, kind: .json)
        let decodeFunc = try DecodeFunc(enumConverter: self, type: type).generate()

        return .init(
            typeDecl: typeDecl,
            jsonDecl: jsonDecl,
            decodeFunc: decodeFunc,
            nestedTypeDecls: try converter.convertNestedTypeDecls(type: .enum(type))
        )
    }

    func transpile(type: EnumType, kind: TypeConverter.TypeKind) throws -> TSTypeDecl {
        let genericParameters = converter.transpileGenericParameters(type: .enum(type))

        if type.caseElements.isEmpty {
            return TSTypeDecl(
                name: converter.transpiledName(of: .enum(type), kind: kind.toNameKind()),
                genericParameters: genericParameters,
                type: .named("never")
            )
        } else if try converter.isStringRawValueType(type: .enum(type)) {
            let items: [TSType] = type.caseElements.map { (ce) in
                .stringLiteral(ce.name)
            }

            return TSTypeDecl(
                name: converter.transpiledName(of: .enum(type), kind: kind.toNameKind()),
                genericParameters: genericParameters,
                type: .union(items)
            )
        }

        let items: [TSType] = try type.caseElements.map { (ce) in
            .record(try transpile(caseElement: ce, kind: kind))
        }

        return TSTypeDecl(
            name: converter.transpiledName(of: .enum(type), kind: kind.toNameKind()),
            genericParameters: genericParameters,
            type: .union(items)
        )
    }

    private func transpile(
        caseElement: CaseElement,
        kind: TypeConverter.TypeKind
    ) throws -> TSRecordType {
        var outerFields: [TSRecordType.Field] = []

        switch kind {
        case .type:
            outerFields.append(
                .init(name: "kind", type: .stringLiteral(caseElement.name))
            )
        case .json:
            break
        }

        var innerFields: [TSRecordType.Field] = []

        for (i, av) in caseElement.associatedValues.enumerated() {
            let field = try transpile(associatedValue: av, index: i, kind: kind)
            innerFields.append(field)
        }

        outerFields.append(
            .init(
                name: caseElement.name,
                type: .record(innerFields)
            )
        )

        return TSRecordType(outerFields)
    }

    private func transpile(
        associatedValue av: AssociatedValue,
        index: Int,
        kind: TypeConverter.TypeKind
    ) throws -> TSRecordType.Field {
        let fieldName = Utils.label(of: av, index)
        let (fieldType, isOptional) = try Utils.unwrapOptional(try av.type(), limit: 1)

        let fieldTypeTS = try converter.transpileFieldTypeReference(
            fieldType: fieldType, kind: kind
        )

        return .init(
            name: fieldName,
            type: fieldTypeTS,
            isOptional: isOptional
        )
    }

    struct DecodeFunc {
        var enumConverter: EnumConverter
        var converter: TypeConverter { enumConverter.converter }

        var type: EnumType

        private func condCode(caseElement ce: CaseElement) -> TSExpr {
            return .infixOperator(
                .stringLiteral(ce.name),
                "in",
                .identifier("json")
            )
        }

        private func decodeCaseObject(
            caseElement ce: CaseElement,
            json: TSExpr
        ) throws -> TSExpr {
            var fields: [TSObjectField] = []

            for (i, av) in ce.associatedValues.enumerated() {
                let fieldName = Utils.label(of: av, i)
                let (fieldType, isOptional) = try Utils.unwrapOptional(try av.type(), limit: 1)

                var value: TSExpr = .memberAccess(base: json, name: fieldName)

                if try !converter.hasEmptyDecoder(type: fieldType) {
                    let decode = converter.transpiledName(of: fieldType, kind: .decode)
                    value = .call(
                        callee: .identifier(decode),
                        arguments: .init([.init(value)])
                    )
                }

                fields.append(.init(
                    name: .identifier(fieldName),
                    value: value
                ))
            }

            return .object(fields)
        }

        private func thenCode(caseElement ce: CaseElement) throws -> TSStmt {
            let varDecl = TSVarDecl(
                mode: "const", name: "j",
                initializer: .memberAccess(
                    base: .identifier("json"),
                    name: ce.name
                )
            )

            let fields: [TSObjectField] = [
                .init(
                    name: .identifier("kind"),
                    value: .stringLiteral(ce.name)
                ),
                .init(
                    name: .identifier(ce.name),
                    value: try decodeCaseObject(
                        caseElement: ce,
                        json: .identifier("j")
                    )
                )
            ]

            return .block([
                .decl(.var(varDecl)),
                .stmt(.return(.object(fields)))
            ])
        }

        private func lastElseCode() -> TSStmt {
            return .block([
                .stmt(.throw(.new(
                    callee: .identifier("Error"),
                    arguments: [
                        TSFunctionArgument(.stringLiteral("unknown kind"))
                    ]
                )))
            ])
        }

        func generate() throws -> TSFunctionDecl {
            let genericParameters = converter.transpileGenericParameters(type: .enum(type))
            let genericArguments: [TSGenericArgument] = genericParameters.map { (param) in
                TSGenericArgument(param.type)
            }

            let typeName = converter.transpiledName(of: .enum(type), kind: .type)
            let jsonName = converter.transpiledName(of: .enum(type), kind: .json)
            let funcName = converter.transpiledName(of: .enum(type), kind: .decode)

            let parameters: [TSFunctionParameter] = [
                .init(
                    name: "json",
                    type: .named(jsonName, genericArguments: genericArguments)
                )
            ]

            var topStmt: TSStmt?

            func appendElse(stmt: TSStmt) {
                if case .if(let top) = topStmt {
                    topStmt = .if(appendElse(stmt: stmt, to: top))
                } else {
                    topStmt = stmt
                }
            }

            func appendElse(stmt: TSStmt, to ifStmt: TSIfStmt) -> TSIfStmt {
                var ifStmt = ifStmt

                if case .if(let nextIf) = ifStmt.else {
                    ifStmt.else = .if(appendElse(stmt: stmt, to: nextIf))
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

                appendElse(stmt: .if(ifSt))
            }

            appendElse(stmt: lastElseCode())

            var items: [TSBlockItem] = []
            if let top = topStmt {
                items.append(.stmt(top))
            }

            return TSFunctionDecl(
                name: funcName,
                genericParameters: genericParameters,
                parameters: parameters,
                returnType: .named(typeName, genericArguments: genericArguments),
                items: items
            )
        }
    }

}
