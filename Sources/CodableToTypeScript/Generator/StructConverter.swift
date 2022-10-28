import SwiftTypeReader
import TSCodeModule

struct StructConverter {
    init(
        converter: TypeConverter
    ) {
        self.converter = converter
    }

    private var converter: TypeConverter

    private var typeMap: TypeMap { converter.typeMap }

    func convert(type: StructType) throws -> TypeConverter.TypeResult {
        let typeDecl = try transpile(type: type, kind: .type)

        var jsonDecl: TSTypeDecl?
        var decodeFunc: TSFunctionDecl?

        if try converter.hasJSONType(type: .struct(type)) {
            jsonDecl = try transpile(type: type, kind: .json)
            decodeFunc = try generateDecodeFunc(type: type)
        }

        return .init(
            typeDecl: typeDecl,
            jsonDecl: jsonDecl,
            decodeFunc: decodeFunc,
            nestedTypeDecls: try converter.convertNestedTypeDecls(type: .struct(type))
        )
    }

    private func transpile(type: StructType, kind: TypeConverter.TypeKind) throws -> TSTypeDecl {
        var fields: [TSRecordType.Field] = []

        for property in type.storedProperties {
            let fieldName = property.name
            let (type, isOptional) = try Utils.unwrapOptional(try property.type(), limit: 1)
            let fieldType = try converter.transpileTypeReference(type, kind: kind)

            fields.append(
                .init(name: fieldName, type: fieldType, isOptional: isOptional)
            )
        }

        return TSTypeDecl(
            name: converter.transpiledName(of: .struct(type), kind: kind.toNameKind()),
            genericParameters: converter.transpileGenericParameters(type: .struct(type)),
            type: .record(TSRecordType(fields))
        )
    }

    private func generateDecodeFunc(type: StructType) throws -> TSFunctionDecl {
        let typeName = converter.transpiledName(of: .struct(type), kind: .type)
        let jsonName = converter.transpiledName(of: .struct(type), kind: .json)
        let funcName = converter.transpiledName(of: .struct(type), kind: .decode)

        let genericParameters = converter.transpileGenericParameters(type: .struct(type))
        let genericArguments: [TSType] = genericParameters.items.map { .named($0) }
        var parameters: [TSFunctionParameter] = [
            .init(
                name: "json",
                type: .named(jsonName, genericArguments: genericArguments)
            )
        ]

        var body: [String] = ["""
return {
"""
        ]

        for (index, field) in type.storedProperties.enumerated() {
            var expr = "json.\(field.name)"

            let fieldType = try field.type()
            if try converter.hasJSONType(type: fieldType) {
                let decode = converter.transpiledName(of: fieldType, kind: .decode)
                expr = "\(decode)(\(expr))"
            }

            let comma: String = {
                if index < type.storedProperties.count - 1 {
                    return ","
                } else {
                    return ""
                }
            }()


            body.append("""
    \(field.name): \(expr)\(comma)
""")
        }

        body.append("""
};
"""
        )

        return TSFunctionDecl(
            name: funcName,
            genericParameters: genericParameters,
            parameters: parameters,
            returnType: .named(typeName, genericArguments: genericArguments),
            body: body
        )
    }

}
