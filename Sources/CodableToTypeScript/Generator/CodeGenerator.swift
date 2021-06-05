import Foundation
import SwiftTypeReader
import TSCodeModule

public final class CodeGenerator {
    public var typeMap: TypeMap

    public init(typeMap: TypeMap) {
        self.typeMap = typeMap
    }

    public func generate(type: Type) -> TSCode {
        let impl = CodeGeneratorImpl(typeMap: typeMap)
        impl.generate(type: type)
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

    func generate(type: Type) {
        switch type {
        case .enum(let type):
            let ret = EnumConverter(typeMap: typeMap).convert(type: type)
            code.decls += [
                .typeDecl(name: ret.jsonTypeName, type: .union(ret.jsonType)),
                .typeDecl(name: ret.taggedTypeName, type: .union(ret.taggedType)),
                .custom(ret.decodeFunc)
            ]
        case .struct(let type):
            fatalError()
        case .unresolved:
            break
        }
    }
}
