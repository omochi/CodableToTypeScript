import SwiftTypeReader
import TSCodeModule

final class EnumConverter {
    struct Value {
        var jsonTypeName: String
        var jsonType: TSUnionType
        var typeName: String
        var type: TSUnionType
    }

//    func convert(type: EnumType) -> Value {
//
//        var caseTypes: [
//    }

    private let typeMap: TypeMap

    init(typeMap: TypeMap) {
        self.typeMap = typeMap
    }

    func transpile(type: EnumType) -> TSUnionType {
        var itemTypes: [TSType] = []

        for ce in type.caseElements {
            let record = transpile(caseElement: ce)
            itemTypes.append(.record(record))
        }

        return TSUnionType(itemTypes)
    }

    private func transpile(caseElement: CaseElement) -> TSRecordType {
        var fields: [TSRecordType.Field] = []

        for (i, av) in caseElement.associatedValues.enumerated() {
            let fieldName = Utils.label(of: av, i)

            let (midType, isOuterOptional) = Utils.unwrapOptional(av.type, limit: 1)
            let (type, isMidOptional) = Utils.unwrapOptional(midType, limit: nil)

            let typeName = typeMap.map(name: type.name)
            var fieldType: TSType = .named(typeName)

            if isMidOptional {
                fieldType = .union([fieldType, .named("null")])
            }

            let field = TSRecordType.Field(
                name: fieldName,
                type: fieldType,
                isOptional: isOuterOptional
            )
            fields.append(field)
        }

        return TSRecordType([
            .init(
                name: caseElement.name,
                type: .record(fields)
            )
        ])
    }

}
