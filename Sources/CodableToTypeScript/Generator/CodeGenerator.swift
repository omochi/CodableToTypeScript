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
        switch type.state {
        case .resolved(.enum(let type)):
            let ret = try EnumConverter(typeMap: typeMap).convert(type: type)
            code.decls += [
                .typeDecl(name: ret.jsonTypeName, type: .union(ret.jsonType)),
                .typeDecl(name: ret.taggedTypeName, type: .union(ret.taggedType)),
                .custom(ret.decodeFunc)
            ]
        case .resolved(.struct(let type)):
            let ret = try StructConverter(typeMap: typeMap).convert(type: type)
            code.decls += [
                .typeDecl(name: type.name, type: .record(ret))
            ]
        case .resolved(.protocol),
             .unresolved:
            break
        }
    }
}
