import SwiftTypeReader
import TSCodeModule

struct EnumConverter {
    init(converter: TypeConverter) {
        self.converter = converter
    }

    private var converter: TypeConverter
    private var typeMap: TypeMap { converter.typeMap }

    enum TypeResult {
        case stringRawValue(
            typeDecl: TSTypeDecl
        )

        case associatedValue(
            jsonTypeDecl: TSTypeDecl,
            taggedTypeDecl: TSTypeDecl,
            decodeFunc: TSFunctionDecl
        )

        case never(
            typeDecl: TSTypeDecl
        )

        var decls: [TSDecl] {
            switch self {
            case .stringRawValue(typeDecl: let typeDecl):
                return [.typeDecl(typeDecl)]
            case .associatedValue(
                jsonTypeDecl: let jsonTypeDecl,
                taggedTypeDecl: let taggedTypeDecl,
                decodeFunc: let decodeFunc
            ):
                return [
                    .typeDecl(jsonTypeDecl),
                    .typeDecl(taggedTypeDecl),
                    .functionDecl(decodeFunc)
                ]
            case .never(typeDecl: let typeDecl):
                return [.typeDecl(typeDecl)]
            }
        }
    }

    struct Result {
        var type: TypeResult
        var namespaceDecl: TSNamespaceDecl?

        var decls: [TSDecl] {
            var decls: [TSDecl] = type.decls
            if let d = namespaceDecl {
                decls.append(.namespaceDecl(d))
            }
            return decls
        }
    }

    func convert(type: EnumType) throws -> Result {
        let typeResult = try convertType(type: type)

        return Result(
            type: typeResult,
            namespaceDecl: try converter.convertNestedDecls(type: .enum(type))
        )
    }

    private func convertType(type: EnumType) throws -> TypeResult {
        if try Self.isStringRawValueType(type: type) {
            let unionType = try transpile(type: type)
            return .stringRawValue(
                typeDecl: .init(
                    name: type.name, type: .union(unionType)
                )
            )
        }


        let genericParameters = type.genericParameters.map { $0.name }

        if type.caseElements.isEmpty {
            return .never(
                typeDecl: .init(
                    name: type.name,
                    genericParameters: genericParameters,
                    type: .named("never")
                )
            )
        }

        let jsonType = try transpile(type: type)
        let jsonTypeName = try Self.transpiledName(type: type)
        let taggedTypeName = type.name
        let taggedType = Self.makeTaggedType(jsonType: jsonType)

        let decodeFunc = Self.makeDecodeFunc(
            taggedName: taggedTypeName,
            jsonName: jsonTypeName,
            jsonType: jsonType,
            genericParameters: genericParameters
        )

        return .associatedValue(
            jsonTypeDecl: .init(
                name: jsonTypeName,
                genericParameters: genericParameters,
                type: .union(jsonType)
            ),
            taggedTypeDecl: .init(
                name: taggedTypeName,
                genericParameters: genericParameters,
                type: .union(taggedType)
            ),
            decodeFunc: decodeFunc
        )
    }

    func transpile(type: EnumType) throws -> TSUnionType {
        let splitLines: Bool
        var itemTypes: [TSType] = []

        if try Self.isStringRawValueType(type: type) {
            splitLines = true
            for ce in type.caseElements {
                itemTypes.append(.stringLiteral(ce.name))
            }
        } else {
            splitLines = false
            for ce in type.caseElements {
                let record = try transpile(caseElement: ce)
                itemTypes.append(.record(record))
            }
        }

        return TSUnionType(itemTypes, splitLines: splitLines)
    }

    static func isStringRawValueType(type: EnumType) throws -> Bool {
        try type.inheritedTypes().first?.name == "String"
    }

    static func transpiledName(type: EnumType) throws -> String {
        if try isStringRawValueType(type: type) {
            return type.name
        } else {
            return type.name + "JSON"
        }
    }

    private func transpile(caseElement: CaseElement) throws -> TSRecordType {
        var fields: [TSRecordType.Field] = []

        for (i, av) in caseElement.associatedValues.enumerated() {
            let field = try transpile(associatedValue: av, index: i)
            fields.append(field)
        }

        return TSRecordType([
            .init(
                name: caseElement.name,
                type: .record(fields)
            )
        ])
    }

    private func transpile(associatedValue av: AssociatedValue, index: Int) throws -> TSRecordType.Field {
        let fieldName = Utils.label(of: av, index)
        let (type, isOptional) = try Utils.unwrapOptional(try av.type(), limit: 1)
        let fieldType = try converter.transpileTypeReference(type)

        return .init(
            name: fieldName,
            type: fieldType,
            isOptional: isOptional
        )
    }

    static func caseElements(from jsonType: TSUnionType) -> [TSRecordType.Field] {
        jsonType.items.compactMap { (item) in
            guard case .record(let record) = item,
                  let field = record.fields.first else {
                return nil
            }

            return field
        }
    }

    static func makeTaggedType(jsonType: TSUnionType) -> TSUnionType {
        var itemTypes: [TSType] = []

        for caseElement in self.caseElements(from: jsonType) {
            let fields: [TSRecordType.Field] = [
                .init(name: "kind", type: .stringLiteral(caseElement.name)),
                caseElement
            ]

            itemTypes.append(.record(fields))
        }

        return TSUnionType(itemTypes)

    }

    static func makeDecodeFunc(
        taggedName: String,
        jsonName: String,
        jsonType: TSUnionType,
        genericParameters: [String]
    ) -> TSFunctionDecl {
        let genericSignature: String
        if genericParameters.isEmpty {
            genericSignature = ""
        } else {
            genericSignature = "<" +
                genericParameters.joined(separator: ", ") +
                ">"
        }

        let caseElements = self.caseElements(from: jsonType)

        func ifCase(_ ce: TSRecordType.Field, _ i: Int) -> [String] {
            let open: String
            if i == 0 {
                open = "if"
            } else {
                open = "} else if"
            }

            var strs: [String] = """
\(open) ("\(ce.name)" in json) {
    return { "kind": "\(ce.name)", \(ce.name): json.\(ce.name) };
""".components(separatedBy: "\n")


            if i == caseElements.count - 1 {
                strs += """
} else {
    throw new Error("unknown kind");
}
""".components(separatedBy: "\n")
            }

            return strs
        }

        let signature = [
            "\(taggedName)Decode\(genericSignature)(",
            "json: \(jsonName)\(genericSignature)",
            "): ",
            "\(taggedName)\(genericSignature)"
        ].joined()


        let body = caseElements.enumerated().flatMap { (i, ce) in
            ifCase(ce, i)
        }

        return TSFunctionDecl(
            signature: signature,
            body: body
        )
    }
}
