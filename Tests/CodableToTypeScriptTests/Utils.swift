import SwiftTypeReader
import TSCodeModule
import XCTest
@testable import CodableToTypeScript

enum Utils {
    static func generate(
        source: String,
        type: (SType) -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> TSCode {
        let result = try Reader().read(source: source)
        let swType = try XCTUnwrap(
            result.module.types.first(where: type),
            file: file, line: line
        )
        return try CodeGenerator(typeMap: .default)(type: swType)
    }
}
