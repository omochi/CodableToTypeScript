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

        var jsonDecl: TSTypeDecl?
        var decodeFunc: TSFunctionDecl?

        if try converter.hasJSONType(type: .enum(type)) {
            jsonDecl = try transpile(type: type, kind: .json)
            decodeFunc = generateDecodeFunc(type: type)
        }

        return .init(
            typeDecl: typeDecl,
            jsonDecl: jsonDecl,
            decodeFunc: decodeFunc,
            nestedTypeDecls: try converter.convertNestedTypeDecls(type: .enum(type))
        )
    }

    func transpile(type: EnumType, kind: TypeConverter.TypeKind) throws -> TSTypeDecl {
        let genericParameters = type.genericParameters.map { $0.name }

        if type.caseElements.isEmpty {
            return .init(
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
        let (type, isOptional) = try Utils.unwrapOptional(try av.type(), limit: 1)
        let fieldType = try converter.transpileTypeReference(type, kind: kind)

        return .init(
            name: fieldName,
            type: fieldType,
            isOptional: isOptional
        )
    }

    private func caseElements(from jsonType: TSUnionType) -> [TSRecordType.Field] {
        jsonType.items.compactMap { (item) in
            guard case .record(let record) = item,
                  let field = record.fields.first else {
                return nil
            }

            return field
        }
    }

    func generateDecodeFunc(type: EnumType) -> TSFunctionDecl {
        func ifCase(index: Int, caseElement ce: CaseElement) -> [String] {
            let open: String
            if index == 0 {
                open = "if"
            } else {
                open = "} else if"
            }

            var strs: [String] = """
\(open) ("\(ce.name)" in json) {
    return { "kind": "\(ce.name)", \(ce.name): json.\(ce.name) };
""".components(separatedBy: "\n")


            if index == type.caseElements.count - 1 {
                strs += """
} else {
    throw new Error("unknown kind");
}
""".components(separatedBy: "\n")
            }

            return strs
        }

        let genericSignature = converter.genericSignature(type: .enum(type))

        let typeName = converter.transpiledName(of: .enum(type), kind: .type)
        let jsonName = converter.transpiledName(of: .enum(type), kind: .json)

        let signature = [
            converter.transpiledName(of: .enum(type), kind: .decode),
            genericSignature,
            "(json: \(jsonName)\(genericSignature)): ",
            "\(typeName)\(genericSignature)"
        ].joined()


        let body = type.caseElements.enumerated().flatMap { (i, ce) in
            ifCase(index: i, caseElement: ce)
        }

        return TSFunctionDecl(
            signature: signature,
            body: body
        )
    }
}
