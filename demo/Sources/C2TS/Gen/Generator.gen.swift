import CodableToTypeScript
import Foundation
import SwiftTypeReader
import TypeScriptAST
import WasmCallableKit

func buildGeneratorMetadata() -> ClassMetadata<Generator> {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .millisecondsSince1970
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .millisecondsSince1970
    var meta = ClassMetadata<Generator>()
    meta.inits.append { _ in
        return Generator()
    }
    meta.methods.append { `self`, argData in
        struct Params: Decodable {
            var _0: String
        }
        let args = try decoder.decode(Params.self, from: argData)
        let ret = try self.tsTypes(
            swiftSource: args._0
        )
        return try encoder.encode(ret)
    }
    meta.methods.append { `self`, _ in
        let ret = self.commonLib()
        return try encoder.encode(ret)
    }
    return meta
}