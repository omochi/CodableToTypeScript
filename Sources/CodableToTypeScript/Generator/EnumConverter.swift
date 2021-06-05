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
            let field = transpile(associatedValue: av, index: i)
            fields.append(field)
        }

        return TSRecordType([
            .init(
                name: caseElement.name,
                type: .record(fields)
            )
        ])
    }

    private func transpile(associatedValue av: AssociatedValue, index: Int) -> TSRecordType.Field {
        let fieldName = Utils.label(of: av, index)
        let (type, isOuterOptional) = Utils.unwrapOptional(av.type, limit: 1)
        let fieldType = transpile(fieldType: type)

        return .init(
            name: fieldName,
            type: fieldType,
            isOptional: isOuterOptional
        )
    }

    private func transpile(fieldType: Type) -> TSType {
        let (unwrappedFieldType, isWrapped) = Utils.unwrapOptional(fieldType, limit: nil)
        if isWrapped {
            let wrapped = transpile(fieldType: unwrappedFieldType)
            return .union([wrapped, .named("null")])
        }

        if let st = fieldType.struct,
           st.name == "Array",
           st.genericsArguments.count > 0
        {
            let element = transpile(fieldType: st.genericsArguments[0])
            return .array(element)
        }

        let typeName = typeMap.map(name: fieldType.name)
        return .named(typeName)
    }

}
