import SwiftTypeReader
import TSCodeModule

final class EnumConverter {
    private let typeMap: TypeMap

    init(typeMap: TypeMap) {
        self.typeMap = typeMap
    }

    enum Value {
        case stringRawValue(
                typeName: String, type: TSUnionType
             )
        case associatedValue(
                jsonTypeName: String,
                jsonType: TSUnionType,
                taggedTypeName: String,
                taggedType: TSUnionType,
                decodeFunc: String
             )

        var typeDecls: [TSTypeDecl] {
            switch self {
            case .stringRawValue(typeName: let typeName, type: let type):
                return [.init(name: typeName, type: .union(type))]
            case .associatedValue(
                    jsonTypeName: let jsonTypeName, jsonType: let jsonType,
                    taggedTypeName: let taggedTypeName,
                    taggedType: let taggedType,
                    decodeFunc: _):
                return [
                    .init(name: jsonTypeName, type: .union(jsonType)),
                    .init(name: taggedTypeName, type: .union(taggedType))
                ]
            }
        }

        var customDecls: [String] {
            switch self {
            case .stringRawValue: return []
            case .associatedValue(
                    jsonTypeName: _, jsonType: _,
                    taggedTypeName: _, taggedType: _,
                    decodeFunc: let decodeFunc):
                return [decodeFunc]
            }
        }
    }

    func convert(type: EnumType) throws -> Value {
        if try Self.isStringRawValueType(type: type) {
            let unionType = try transpile(type: type)
            return .stringRawValue(
                typeName: type.name,
                type: unionType
            )
        }

        let jsonType = try transpile(type: type)
        let jsonTypeName = try Self.transpiledName(type: type)
        let taggedTypeName = type.name
        let taggedType = Self.makeTaggedType(jsonType: jsonType)
        let genericParameters = type.genericParameters.map { $0.name }
        let decodeFunc = Self.makeDecodeFunc(
            taggedName: taggedTypeName,
            jsonName: jsonTypeName,
            jsonType: jsonType,
            genericParameters: genericParameters
        )

        return .associatedValue(
            jsonTypeName: jsonTypeName,
            jsonType: jsonType,
            taggedTypeName: taggedTypeName,
            taggedType: taggedType,
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
        let fieldType = try StructConverter.transpile(typeMap: typeMap, type: type)

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
    ) -> String {
        let genericSignature: String
        if genericParameters.isEmpty {
            genericSignature = ""
        } else {
            genericSignature = "<" +
                genericParameters.joined(separator: ", ") +
                ">"
        }

        let caseElements = self.caseElements(from: jsonType)

        func ifCase(_ ce: TSRecordType.Field, _ i: Int) -> String {
            let open: String
            if i == 0 {
                open = "if"
            } else {
                open = "} else if"
            }


            var str = """
    \(open) ("\(ce.name)" in json) {
        return { "kind": "\(ce.name)", \(ce.name): json.\(ce.name) };
"""

            if i == caseElements.count - 1 {
                str += "\n"
                str += """
    } else {
        throw new Error("unknown kind");
    }
"""
            }

            return str
        }

        let title = [
            "export function ",
            "\(taggedName)Decode\(genericSignature)(",
            "json: \(jsonName)\(genericSignature)",
            "): ",
            "\(taggedName)\(genericSignature)"
        ].joined()

        return """
\(title) {
\(lines: caseElements.enumerated(), { (i, ce) in
    ifCase(ce, i)
})
}

"""


    }
}
