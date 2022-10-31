import Foundation
import SwiftTypeReader
import TSCodeModule

public struct CodeGenerator {
    public static let defaultKnownNames: Set<String> = [
        "never",
        "void",
        "null",
        "undefined",
        "boolean",
        "number",
        "string",
        "Error"
    ]

    public var typeMap: TypeMap {
        didSet {
            // reset cache
            typeConverter = TypeConverter(typeMap: typeMap)
        }
    }

    public var knownNames: Set<String>
    public var importFrom: String?

    private var typeConverter: TypeConverter


    public init(
        typeMap: TypeMap = .default,
        knownNames: Set<String> = Self.defaultKnownNames,
        importFrom: String? = ".."
    ) {
        self.typeMap = typeMap
        self.knownNames = knownNames
        self.importFrom = importFrom
        self.typeConverter = TypeConverter(typeMap: typeMap)
    }

    @available(*, deprecated, message: "Use `generateTypeDeclarationFile`")
    public func callAsFunction(type: SType) throws -> TSCode {
        try generateTypeDeclarationFile(type: type)
    }

    public func generateTypeOwnDeclarations(type: SType) throws -> TypeOwnDeclarations {
        try typeConverter.generateTypeOwnDeclarations(type: type)
    }

    public func generateTypeDeclaration(type: SType) throws -> TSTypeDecl {
        try typeConverter.generateTypeDeclaration(type: type)
    }

    public func hasTranspiledJSONType(type: SType) throws -> Bool {
        try !typeConverter.hasEmptyDecoder(type: type)
    }

    public func generateJSONTypeDeclaration(type: SType) throws -> TSTypeDecl? {
        try typeConverter.generateJSONTypeDeclaration(type: type)
    }

    public func generateDecodeFunction(type: SType) throws -> TSFunctionDecl? {
        try typeConverter.generateDecodeFunction(type: type)
    }

    public func generateTypeDeclarationFile(type: SType) throws -> TSCode {
        var decls: [TSDecl] = []

        func walk(type: SType) throws {
            decls += try generateTypeOwnDeclarations(type: type).decls

            for type in type.regular?.types ?? [] {
                try walk(type: type)
            }
        }

        try walk(type: type)

        if let from = importFrom {
            let deps = DependencyScanner(knownNames: knownNames).scan(
                code: TSCode(decls.map { .decl($0) })
            )
            if !deps.isEmpty {
                let imp = TSImportDecl(names: deps, from: from)
                decls.insert(.`import`(imp), at: 0)
            }
        }

        return TSCode(decls.map { .decl($0) })
    }

    public func transpileTypeReference(type: SType) throws -> TSType {
        return try typeConverter.transpileTypeReference(type, kind: .type)
    }

    public func transpileTypeReferenceToJSON(type: SType) throws -> TSType {
        return try typeConverter.transpileTypeReference(type, kind: .json)
    }

    public func generateHelperLibrary() -> TSCode {
        return typeConverter.helperLibrary().generate()
    }

    public func generateDecodeFieldExpression(type: SType, expr: TSExpr) throws -> TSExpr {
        return try typeConverter.decodeFunction().decodeField(type: type, expr: expr)
    }

    public func generateDecodeValueExpression(type: SType, expr: TSExpr) throws -> TSExpr {
        return try typeConverter.decodeFunction().decodeValue(type: type, expr: expr)
    }
}
