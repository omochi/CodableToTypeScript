import SwiftTypeReader
import TSCodeModule

final class StructConverter {
    private let typeMap: TypeMap

    init(typeMap: TypeMap) {
        self.typeMap = typeMap
    }

    func convert(type: StructType) throws -> TSRecordType {
        var fields: [TSRecordType.Field] = []

        for property in type.storedProperties {
            let fieldName = property.name
            let (type, isOptional) = try Utils.unwrapOptional(try property.type(), limit: 1)
            let fieldType = try Self.transpile(typeMap: typeMap, fieldType: type)

            fields.append(
                .init(name: fieldName, type: fieldType, isOptional: isOptional)
            )
        }

        return TSRecordType(fields)
    }

    static func transpile(typeMap: TypeMap, fieldType: SType) throws -> TSType {
        let (unwrappedFieldType, isWrapped) = try Utils.unwrapOptional(fieldType, limit: nil)
        if isWrapped {
            let wrapped = try transpile(
                typeMap: typeMap,
                fieldType: unwrappedFieldType
            )
            return .union([wrapped, .named("null")])
        } else if let st = fieldType.struct,
                  st.name == "Array",
                  try st.genericArguments().count >= 1
        {
            let element = try transpile(
                typeMap: typeMap,
                fieldType: try st.genericArguments()[0]
            )
            return .array(element)
        } else if let st = fieldType.struct,
                  st.name == "Dictionary",
                  try st.genericArguments().count >= 2
        {
            let element = try transpile(
                typeMap: typeMap,
                fieldType: try st.genericArguments()[1]
            )
            return .dictionary(element)
        } else {
            let typeName = typeMap.map(name: fieldType.name)
            return .named(typeName)
        }
    }

}
