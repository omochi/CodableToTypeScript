import SwiftTypeReader
import TypeScriptAST

struct ErrorTypeConverter: TypeConverter {
    var generator: CodeGenerator
    var swiftType: any SType

    func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        throw MessageError("Error type can't be converted: \(swiftType)")
    }

    func decodePresence() throws -> CodecPresence {
        throw MessageError("Error type can't be evaluated: \(swiftType)")
    }

    func hasDecode() throws -> Bool {
        throw MessageError("Error type can't be converted: \(swiftType)")
    }

    func decodeDecl() throws -> TSFunctionDecl? {
        throw MessageError("Error type can't be converted: \(swiftType)")
    }

    func hasEncode() throws -> Bool {
        throw MessageError("Error type can't be evaluated: \(swiftType)")
    }

    func encodePresence() throws -> CodecPresence {
        throw MessageError("Error type can't be evaluated: \(swiftType)")
    }

    func encodeDecl() throws -> TSFunctionDecl? {
        throw MessageError("Error type can't be converted: \(swiftType)")
    }
}
