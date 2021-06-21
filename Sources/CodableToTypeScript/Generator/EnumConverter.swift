import SwiftTypeReader
import TSCodeModule

final class EnumConverter {
    private let typeMap: TypeMap

    init(typeMap: TypeMap) {
        self.typeMap = typeMap
    }

    struct Value {
        var jsonTypeName: String
        var jsonType: TSUnionType
        var taggedTypeName: String
        var taggedType: TSUnionType
        var decodeFunc: String
    }

    func convert(type: EnumType) throws -> Value {
        let jsonType = try transpile(type: type)
        let jsonTypeName = type.name + "JSON"
        let taggedTypeName = type.name
        let taggedType = Self.makeTaggedType(jsonType: jsonType)
        let genericParameters = type.genericParameters.map { $0.name }
        let decodeFunc = Self.makeDecodeFunc(
            taggedName: taggedTypeName,
            jsonName: jsonTypeName,
            jsonType: jsonType,
            genericParameters: genericParameters
        )
        return Value(
            jsonTypeName: jsonTypeName,
            jsonType: jsonType,
            taggedTypeName: taggedTypeName,
            taggedType: taggedType,
            decodeFunc: decodeFunc
        )
    }

    func transpile(type: EnumType) throws -> TSUnionType {
        var itemTypes: [TSType] = []

        for ce in type.caseElements {
            let record = try transpile(caseElement: ce)
            itemTypes.append(.record(record))
        }

        return TSUnionType(itemTypes)
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
