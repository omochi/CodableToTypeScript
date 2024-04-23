import SwiftTypeReader
import TypeScriptAST

public struct GenericParamConverter: TypeConverter {
    public init(generator: CodeGenerator, param: GenericParamType) {
        self.generator = generator
        self.param = param
    }
    
    public var generator: CodeGenerator
    public var param: GenericParamType
    public var swiftType: any SType { param }

    public func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        throw MessageError("Unsupported type: \(swiftType)")
    }

    public func hasDecode() throws -> Bool {
        return true
    }

    public func decodeDecl() throws -> TSFunctionDecl? {
        throw MessageError("Unsupported type: \(swiftType)")
    }

    public func hasEncode() throws -> Bool {
        return true
    }

    public func encodeDecl() throws -> TSFunctionDecl? {
        throw MessageError("Unsupported type: \(swiftType)")
    }
}
