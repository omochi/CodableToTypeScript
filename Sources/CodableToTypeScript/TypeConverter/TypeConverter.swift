import SwiftTypeReader
import TypeScriptAST

public protocol TypeConverter {
    var generator: CodeGenerator { get }
    var type: any SType { get }
    func name(for target: GenerationTarget) throws -> String
    func hasJSONType() throws -> Bool
    func type(for target: GenerationTarget) throws -> any TSType
    func fieldType(for target: GenerationTarget) throws -> (type: any TSType, isOptional: Bool)
    func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl?
    func hasDecode() throws -> Bool
    func decodeName() throws -> String
    func boundDecode() throws -> any TSExpr
    func callDecode(json: any TSExpr) throws -> any TSExpr
    func callDecodeField(json: any TSExpr) throws -> any TSExpr
    func decodeSignature() throws -> TSFunctionDecl?
    func decodeDecl() throws -> TSFunctionDecl?
    func hasEncode() throws -> Bool
    func encodeName() throws -> String
    func boundEncode() throws -> any TSExpr
    func callEncode(entity: any TSExpr) throws -> any TSExpr
    func callEncodeField(entity: any TSExpr) throws -> any TSExpr
    func encodeSignature() throws -> TSFunctionDecl?
    func encodeDecl() throws -> TSFunctionDecl?
    func ownDecls() throws -> TypeOwnDeclarations
    func source() throws -> TSSourceFile
}

extension TypeConverter {
    // MARK: - defaults
    public var `default`: DefaultTypeConverter {
        return DefaultTypeConverter(generator: generator, type: type)
    }

    public func name(for target: GenerationTarget) throws -> String {
        return try `default`.name(for: target)
    }

    public func hasJSONType() throws -> Bool {
        return try `default`.hasJSONType()
    }

    public func type(for target: GenerationTarget) throws -> any TSType {
        return try `default`.type(for: target)
    }

    public func fieldType(for target: GenerationTarget) throws -> (type: any TSType, isOptional: Bool) {
        return try `default`.fieldType(for: target)
    }

    public func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        return try `default`.typeDecl(for: target)
    }

    public func decodeName() throws -> String {
        return try `default`.decodeName()
    }

    public func boundDecode() throws -> any TSExpr {
        return try `default`.boundDecode()
    }

    public func callDecode(json: any TSExpr) throws -> any TSExpr {
        return try `default`.callDecode(json: json)
    }

    public func callDecodeField(json: any TSExpr) throws -> any TSExpr {
        return try `default`.callDecodeField(json: json)
    }

    public func decodeSignature() throws -> TSFunctionDecl? {
        return try `default`.decodeSignature()
    }

    public func decodeDecl() throws -> TSFunctionDecl? {
        return try `default`.decodeDecl()
    }

    public func encodeName() throws -> String {
        return try `default`.encodeName()
    }

    public func boundEncode() throws -> any TSExpr {
        return try `default`.boundEncode()
    }

    public func callEncode(entity: any TSExpr) throws -> any TSExpr {
        return try `default`.callEncode(entity: entity)
    }

    public func callEncodeField(entity: any TSExpr) throws -> any TSExpr {
        return try `default`.callEncodeField(entity: entity)
    }

    public func encodeSignature() throws -> TSFunctionDecl? {
        return try `default`.encodeSignature()
    }

    public func encodeDecl() throws -> TSFunctionDecl? {
        return try `default`.encodeDecl()
    }

    // MARK: - extensions
    public func genericArgs() throws -> [any TypeConverter] {
        return try type.genericArgs.map { (type) in
            try generator.converter(for: type)
        }
    }

    public func genericParams() throws -> [any TypeConverter] {
        guard let decl = self.type.typeDecl,
              let genericContext = decl as? any GenericContext else
        {
            return []
        }
        return try genericContext.genericParams.items.map { (param) in
            try generator.converter(for: param)
        }
    }

    public func ownDecls() throws -> TypeOwnDeclarations {
        return TypeOwnDeclarations(
            entityType: try typeDecl(for: .entity).unwrap(name: "entity type decl"),
            jsonType: try typeDecl(for: .json),
            decodeFunction: try decodeDecl(),
            encodeFunction: try encodeDecl()
        )
    }

    public func source() throws -> TSSourceFile {
        var decls: [any ASTNode] = []

        if let typeDecl = type.typeDecl {
            try typeDecl.walk { (type) in
                let converter = try generator.converter(for: type.declaredInterfaceType)
                decls += try converter.ownDecls().decls
            }
        }

        return TSSourceFile(decls)
    }
}
