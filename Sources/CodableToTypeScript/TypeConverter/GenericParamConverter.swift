import SwiftTypeReader
import TypeScriptAST

struct GenericParamConverter: TypeConverter {
    var generator: CodeGenerator
    var param: GenericParamType
    var swiftType: any SType { param }
    
    func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        throw MessageError("Unsupported type: \(swiftType)")
    }

    func hasDecode() throws -> Bool {
        return true
    }

    func decodePresence() throws -> CodecPresence {
        return .conditional
    }

    func decodeDecl() throws -> TSFunctionDecl? {
        throw MessageError("Unsupported type: \(swiftType)")
    }

    func hasEncode() throws -> Bool {
        return true
    }

    func encodePresence() throws -> CodecPresence {
        return .conditional
    }

    func encodeDecl() throws -> TSFunctionDecl? {
        throw MessageError("Unsupported type: \(swiftType)")
    }
}
