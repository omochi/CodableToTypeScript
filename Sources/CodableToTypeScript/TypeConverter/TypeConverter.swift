import SwiftTypeReader
import TypeScriptAST

public protocol TypeConverter {
    var generator: CodeGenerator { get }
    var swiftType: any SType { get }
    func name(for target: GenerationTarget) throws -> String
    func hasJSONType() throws -> Bool
    func type(for target: GenerationTarget) throws -> any TSType
    func fieldType(for target: GenerationTarget) throws -> (type: any TSType, isOptional: Bool)
    func valueToField(value: any TSExpr, for target: GenerationTarget) throws -> any TSExpr
    func fieldToValue(field: any TSExpr, for target: GenerationTarget) throws -> any TSExpr
    func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl?
    func hasDecode() throws -> Bool
    func decodePresence() throws -> CodecPresence
    func decodeName() throws -> String
    func boundDecode() throws -> any TSExpr
    func callDecode(json: any TSExpr) throws -> any TSExpr
    func callDecodeField(json: any TSExpr) throws -> any TSExpr
    func decodeSignature() throws -> TSFunctionDecl?
    func decodeDecl() throws -> TSFunctionDecl?
    func hasEncode() throws -> Bool
    func encodePresence() throws -> CodecPresence
    func encodeName() throws -> String
    func boundEncode() throws -> any TSExpr
    func callEncode(entity: any TSExpr) throws -> any TSExpr
    func callEncodeField(entity: any TSExpr) throws -> any TSExpr
    func encodeSignature() throws -> TSFunctionDecl?
    func encodeDecl() throws -> TSFunctionDecl?
    func ownDecls() throws -> TypeOwnDeclarations
    func decls() throws -> [any TSDecl]
}

extension TypeConverter {
    // MARK: - defaults
    public var `default`: DefaultTypeConverter {
        return DefaultTypeConverter(generator: generator, type: swiftType)
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

    public func valueToField(value: any TSExpr, for target: GenerationTarget) throws -> any TSExpr {
        return try `default`.valueToField(value: value, for: target)
    }

    public func fieldToValue(field: any TSExpr, for target: GenerationTarget) throws -> any TSExpr {
        return try `default`.fieldToValue(field: field, for: target)
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

    // MARK: - extensions
    public func genericArgs() throws -> [any TypeConverter] {
        return try swiftType.genericArgs.map { (type) in
            try generator.converter(for: type)
        }
    }

    public func genericParams() throws -> [any TypeConverter] {
        return try genericParams(stype: self.swiftType)
    }

    private func genericParams(stype: any SType) throws -> [any TypeConverter] {
        let parentParams = if let parent = stype.typeDecl?.parentContext,
            let parentType = parent.selfInterfaceType {
                try genericParams(stype: parentType)
            } else {
                [] as [any TypeConverter]
            }

        guard let decl = stype.typeDecl,
              let genericContext = decl as? any GenericContext else
        {
            return parentParams
        }
        return parentParams + (try genericContext.genericParams.items.map { (param) in
            try generator.converter(for: param.declaredInterfaceType)
        })
    }

    public func ownDecls() throws -> TypeOwnDeclarations {
        return TypeOwnDeclarations(
            entityType: try typeDecl(for: .entity),
            jsonType: try typeDecl(for: .json),
            decodeFunction: try decodeDecl(),
            encodeFunction: try encodeDecl()
        )
    }

    public func decls() throws -> [any TSDecl] {
        var decls: [any TSDecl] = []

        if let typeDecl = swiftType.typeDecl {
            try withErrorCollector { collect in
                typeDecl.walkTypeDecls { (type) in
                    if let converter = try? generator.converter(for: type.declaredInterfaceType) {
                        collect(at: "\(type.declaredInterfaceType)") {
                            decls += try converter.ownDecls().decls
                        }
                    }

                    return true
                }
            }
        }

        return decls
    }
}
