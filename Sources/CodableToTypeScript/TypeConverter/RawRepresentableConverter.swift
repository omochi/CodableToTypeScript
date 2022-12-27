import SwiftTypeReader
import TypeScriptAST

struct RawRepresentableConverter: TypeConverter {
    init(
        generator: CodeGenerator,
        swiftType: any SType,
        rawValueType raw: any SType
    ) throws {
        let map = swiftType.contextSubstitutionMap()
        let raw = raw.subst(map: map)

        self.generator = generator
        self.swiftType = swiftType
        self.rawValueType = try generator.converter(for: raw)
    }

    var generator: CodeGenerator
    var swiftType: any SType
    var rawValueType: any TypeConverter

    func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        let name = try self.name(for: target)
        let genericParams: [TSTypeParameterNode] = try self.genericParams().map {
            .init(try $0.name(for: target))
        }
        switch target {
        case .entity:
            let fieldType = try rawValueType.fieldType(for: .entity)

            let field: TSObjectType.Field = .field(
                name: "rawValue", isOptional: fieldType.isOptional, type: fieldType.type
            )

            var type: any TSType = TSObjectType([field])

            let tag = try generator.tagRecord(
                name: name,
                genericArgs: try self.genericParams().map { (param) in
                    TSIdentType(try param.name(for: .entity))
                }
            )

            type = TSIntersectionType(type, tag)

            return TSTypeDecl(
                modifiers: [.export],
                name: name,
                genericParams: genericParams,
                type: type
            )
        case .json:
            return TSTypeDecl(
                modifiers: [.export],
                name: name,
                genericParams: genericParams,
                type: try rawValueType.type(for: target)
            )
        }
    }

    func decodePresence() throws -> CodecPresence {
        return .required
    }

    func decodeDecl() throws -> TSFunctionDecl? {
        guard let decl = try decodeSignature() else { return nil }

        let field = try rawValueType.callDecodeField(json: TSIdentExpr("json"))

        let object = TSObjectExpr([
            .named(name: "rawValue", value: field)
        ])

        decl.body.elements.append(
            TSReturnStmt(object)
        )

        return decl
    }

    func encodePresence() throws -> CodecPresence {
        return try rawValueType.encodePresence()
    }

    func encodeDecl() throws -> TSFunctionDecl? {
        guard let decl = try encodeSignature() else { return nil }

        var expr = try rawValueType.callEncode(entity: TSIdentExpr("entity"))
        expr = TSAsExpr(expr, try self.type(for: .json))
        decl.body.elements.append(
            TSReturnStmt(expr)
        )

        return decl
    }
}
