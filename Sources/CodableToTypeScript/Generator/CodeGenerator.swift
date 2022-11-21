import Foundation
import SwiftTypeReader
import TSCodeModule

public struct CodeGenerator {
    public let context: Context

    public var typeMap: TypeMap {
        didSet {
            // reset cache
            typeConverter = TypeConverter(
                context: context, typeMap: typeMap
            )
        }
    }

    public var knownNames: Set<String>
    public var importFrom: String?

    private var typeConverter: TypeConverter

    public init(
        context: Context,
        typeMap: TypeMap = .default,
        knownNames: Set<String> = DependencyScanner.defaultKnownNames,
        importFrom: String? = ".."
    ) {
        self.context = context
        self.typeMap = typeMap
        self.knownNames = knownNames
        self.importFrom = importFrom
        self.typeConverter = TypeConverter(context: context, typeMap: typeMap)
    }

    @available(*, deprecated, message: "Use `generateTypeDeclarationFile`")
    public func callAsFunction(type: any TypeDecl) throws -> TSCode {
        try generateTypeDeclarationFile(type: type)
    }

    public func generateTypeOwnDeclarations(type: any TypeDecl) throws -> TypeOwnDeclarations {
        try typeConverter.generateTypeOwnDeclarations(type: type)
    }

    public func generateTypeDeclaration(type: any TypeDecl) throws -> TSTypeDecl {
        try typeConverter.generateTypeDeclaration(type: type)
    }

    public func hasTranspiledJSONType(type: any SType) throws -> Bool {
        try !typeConverter.hasEmptyDecoder(type: type)
    }

    public func hasTranspiledJSONType(type: any TypeDecl) throws -> Bool {
        try !typeConverter.hasEmptyDecoder(type: type)
    }

    public func generateJSONTypeDeclaration(type: any TypeDecl) throws -> TSTypeDecl? {
        try typeConverter.generateJSONTypeDeclaration(type: type)
    }

    public func generateDecodeFunction(type: any TypeDecl) throws -> TSFunctionDecl? {
        try typeConverter.generateDecodeFunction(type: type)
    }

    public func generateTypeDeclarationFile(type: any TypeDecl) throws -> TSCode {
        var decls: [TSDecl] = []

        func walk(type: any TypeDecl) throws {
            decls += try generateTypeOwnDeclarations(type: type).decls

            for type in (type as? any NominalTypeDecl)?.types ?? [] {
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

    public func transpileTypeReference(type: any SType) throws -> TSType {
        return try typeConverter.transpileTypeReference(type, kind: .type)
    }

    public func transpileTypeReferenceToJSON(type: any SType) throws -> TSType {
        return try typeConverter.transpileTypeReference(type, kind: .json)
    }

    public func generateHelperLibrary() -> TSCode {
        return typeConverter.helperLibrary().generate()
    }

    public func generateDecodeFieldExpression(type: any SType, expr: TSExpr) throws -> TSExpr {
        return try typeConverter.decodeFunction().decodeField(type: type, expr: expr)
    }

    public func generateDecodeValueExpression(type: any SType, expr: TSExpr) throws -> TSExpr {
        return try typeConverter.decodeFunction().decodeValue(type: type, expr: expr)
    }
}
