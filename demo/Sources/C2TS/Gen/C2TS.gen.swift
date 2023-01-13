import CodableToTypeScript
import Foundation
import SwiftTypeReader
import TypeScriptAST
import WasmCallableKit

func buildC2TSMetadata() -> ClassMetadata<C2TS> {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .millisecondsSince1970
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .millisecondsSince1970
    var meta = ClassMetadata<C2TS>()
    meta.inits.append { _ in
        return C2TS()
    }
    meta.methods.append { `self`, argData in
        struct Params: Decodable {
            var _0: String
        }
        let args = try decoder.decode(Params.self, from: argData)
        let ret = try self.convert(
            swiftSource: args._0
        )
        return try encoder.encode(ret)
    }
    return meta
}