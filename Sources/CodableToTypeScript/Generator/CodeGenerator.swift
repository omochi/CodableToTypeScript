import Foundation
import SwiftTypeReader
import TypeScriptAST

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

    private var typeConverter: TypeConverter

    public init(
        context: Context,
        typeMap: TypeMap = .default
    ) {
        self.context = context
        self.typeMap = typeMap
        self.typeConverter = TypeConverter(context: context, typeMap: typeMap)
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

    public func generateTypeDeclarationFile(type: any TypeDecl) throws -> TSSourceFile {
        var decls: [any ASTNode] = []

        func walk(type: any TypeDecl) throws {
            decls += try generateTypeOwnDeclarations(type: type).decls

            for type in type.asNominalType?.types ?? [] {
                try walk(type: type)
            }
        }

        try walk(type: type)

        return TSSourceFile(decls)
    }

    public func transpileTypeReference(type: any SType) throws -> any TSType {
        return try typeConverter.transpileTypeReference(type, kind: .type)
    }

    public func transpileTypeReferenceToJSON(type: any SType) throws -> any TSType {
        return try typeConverter.transpileTypeReference(type, kind: .json)
    }

    public func generateHelperLibrary() -> TSSourceFile {
        return typeConverter.helperLibrary().generate()
    }

    public func generateDecodeFieldExpression(type: any SType, expr: any TSExpr) throws -> any TSExpr {
        return try typeConverter.decodeFunction().decodeField(type: type, expr: expr)
    }

    public func generateDecodeValueExpression(type: any SType, expr: any TSExpr) throws -> any TSExpr {
        return try typeConverter.decodeFunction().decodeValue(type: type, expr: expr)
    }
}
