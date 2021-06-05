import XCTest
@testable import CodableToTypeScript
import SwiftTypeReader
import TestUtils
import TSCodeModule

final class EnumTests: XCTestCase {
    func testTranspile() throws {
        try assertTranspile("""
enum E {
    case a(x: Int)
    case b(y: String, Int)
}
""","""
{
  a: {
    x: number;
  };
} | {
  b: {
    y: string;
    _1: number;
  };
}
""")
    }

    func testTranspileOptional() throws {
        try assertTranspile("""
enum E {
    case a(Int, Int?, Int??, Int???)
}
""", """
{
  a: {
    _0: number;
    _1?: number;
    _2?: number | null;
    _3?: number | null;
  };
}
""")
    }

    private func assertTranspile(
        _ source: String,
        _ expected: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let module = try Reader().read(source: source)
        let swType = try XCTUnwrap(module.types.compactMap { $0.enum }.first)
        let tsType = EnumConverter(typeMap: .default).transpile(type: swType)
        XCTAssertEqual(tsType.description, expected, file: file, line: line)
    }
}
