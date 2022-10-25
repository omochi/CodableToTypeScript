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
            let fieldType = try Self.transpile(typeMap: typeMap, type: type)

            fields.append(
                .init(name: fieldName, type: fieldType, isOptional: isOptional)
            )
        }

        return TSRecordType(fields)
    }

    static func transpile(typeMap: TypeMap, type: SType) throws -> TSType {
        let (unwrappedFieldType, isWrapped) = try Utils.unwrapOptional(type, limit: nil)
        if isWrapped {
            let wrapped = try transpile(
                typeMap: typeMap,
                type: unwrappedFieldType
            )
            return .union([wrapped, .named("null")])
        } else if let st = type.struct,
                  st.name == "Array",
                  try st.genericArguments().count >= 1
        {
            let element = try transpile(
                typeMap: typeMap,
                type: try st.genericArguments()[0]
            )
            return .array(element)
        } else if let st = type.struct,
                  st.name == "Dictionary",
                  try st.genericArguments().count >= 2
        {
            let element = try transpile(
                typeMap: typeMap,
                type: try st.genericArguments()[1]
            )
            return .dictionary(element)
        }

        let specifier = type.asSpecifier()

        let name: String

        if let mappedName = typeMap.map(specifier: specifier) {
            name = mappedName
        } else if let enumType = type.enum {
            name = try EnumConverter.transpiledName(type: enumType)
        } else {
            name = specifier.lastElement.name
        }

        let args = try type.genericArguments().map {
            try transpile(typeMap: typeMap, type: $0)
        }

        return .named(name, genericArguments: args)
    }
}
