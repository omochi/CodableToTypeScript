import SwiftTypeReader
import TSCodeModule

final class StructConverter {
    private let typeMap: TypeMap

    init(typeMap: TypeMap) {
        self.typeMap = typeMap
    }

    func convert(type: StructType) -> TSRecordType {
        var fields: [TSRecordType.Field] = []

        for property in type.storedProperties {
            let fieldName = property.name
            let (type, isOptional) = Utils.unwrapOptional(property.type, limit: 1)
            let fieldType = Self.transpile(typeMap: typeMap, fieldType: type)

            fields.append(
                .init(name: fieldName, type: fieldType, isOptional: isOptional)
            )
        }

        return TSRecordType(fields)
    }

    static func transpile(typeMap: TypeMap, fieldType: Type) -> TSType {
        let (unwrappedFieldType, isWrapped) = Utils.unwrapOptional(fieldType, limit: nil)
        if isWrapped {
            let wrapped = transpile(
                typeMap: typeMap,
                fieldType: unwrappedFieldType
            )
            return .union([wrapped, .named("null")])
        } else if let st = fieldType.struct,
                  st.name == "Array",
                  st.genericsArguments.count >= 1
        {
            let element = transpile(
                typeMap: typeMap,
                fieldType: st.genericsArguments[0]
            )
            return .array(element)
        } else if let st = fieldType.struct,
                  st.name == "Dictionary",
                  st.genericsArguments.count >= 2
        {
            let element = transpile(
                typeMap: typeMap,
                fieldType: st.genericsArguments[1]
            )
            return .dictionary(element)
        } else {
            let typeName = typeMap.map(name: fieldType.name)
            return .named(typeName)
        }
    }

}
