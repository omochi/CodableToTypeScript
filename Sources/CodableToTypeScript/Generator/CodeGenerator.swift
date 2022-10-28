import Foundation
import SwiftTypeReader
import TSCodeModule

public struct CodeGenerator {
    public static let defaultStandardTypes: Set<String> = [
        "never",
        "void",
        "null",
        "undefined",
        "boolean",
        "number",
        "string",
    ]

    public var typeMap: TypeMap
    public var standardTypes: Set<String>
    public var importFrom: String

    public init(
        typeMap: TypeMap,
        standardTypes: Set<String> = Self.defaultStandardTypes,
        importFrom: String = ".."
    ) {
        self.typeMap = typeMap
        self.standardTypes = standardTypes
        self.importFrom = importFrom
    }

    @available(*, deprecated, message: "Use `generateTypeDeclarationFile`")
    public func callAsFunction(type: SType) throws -> TSCode {
        try generateTypeDeclarationFile(type: type)
    }

    private func typeConverter() -> TypeConverter {
        return TypeConverter(typeMap: typeMap)
    }

    public func generateTypeDeclarationFile(
        type: SType
    ) throws -> TSCode {
        var decls = try typeConverter().convert(type: type)

        let deps = DependencyScanner(standardTypes: standardTypes)
            .scan(code: TSCode(decls.map { .decl($0) }))
        if !deps.isEmpty {
            decls.insert(.import(names: deps, from: importFrom), at: 0)
        }

        return TSCode(decls.map { .decl($0) })
    }

    public func transpileTypeReference(
        type: SType
    ) throws -> TSType {
        return try typeConverter().transpileTypeReference(
            type,
            kind: .type
        )
    }
}
