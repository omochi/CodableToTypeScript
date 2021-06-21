import Foundation
import SwiftTypeReader
import TSCodeModule

public final class CodeGenerator {
    public var typeMap: TypeMap

    public init(typeMap: TypeMap) {
        self.typeMap = typeMap
    }

    public func generate(type: SType) throws -> TSCode {
        let impl = CodeGeneratorImpl(typeMap: typeMap)
        try impl.generate(type: type)
        return impl.code
    }
}

final class CodeGeneratorImpl {
    init(typeMap: TypeMap, code: TSCode = TSCode(decls: [])) {
        self.typeMap = typeMap
        self.code = code
    }

    let typeMap: TypeMap
    var code: TSCode

    func generate(type: SType) throws {
        guard let type = type.regular else {
            return
        }
        switch type {
        case .enum(let type):
            let genericParameters = type.genericParameters.map { $0.name }
            let ret = try EnumConverter(typeMap: typeMap).convert(type: type)
            code.decls += [
                .typeDecl(
                    name: ret.jsonTypeName,
                    genericParameters: genericParameters,
                    type: .union(ret.jsonType)
                ),
                .typeDecl(
                    name: ret.taggedTypeName,
                    genericParameters: genericParameters,
                    type: .union(ret.taggedType)
                ),
                .custom(ret.decodeFunc)
            ]
        case .struct(let type):
            let genericParameters = type.genericParameters.map { $0.name }
            let ret = try StructConverter(typeMap: typeMap).convert(type: type)
            code.decls += [
                .typeDecl(
                    name: type.name,
                    genericParameters: genericParameters,
                    type: .record(ret)
                )
            ]
        case .protocol,
             .genericParameter:
            return
        }
    }
}
