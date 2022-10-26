import XCTest
import SwiftTypeReader
import TestUtils
import TSCodeModule
@testable import struct CodableToTypeScript.EnumConverter

final class EnumTranspileTests: XCTestCase {
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

    func testTranspileArray() throws {
        try assertTranspile("""
enum E {
    case a([Int], [[Int]], [Int]?, [Int?])
}
""", """
{
    a: {
        _0: number[];
        _1: number[][];
        _2?: number[];
        _3: (number | null)[];
    };
}
""")
    }

    func testTranspileDictionary() throws {
        try assertTranspile("""
enum E {
    case a([String: Int], [String: Int?])
}
""", """
{
    a: {
        _0: { [key: string]: number; };
        _1: { [key: string]: number | null; };
    };
}
""")
    }

    func testTranspileString() throws {
        try assertTranspile("""
enum E: String, Codable {
    case aaa
    case bbb
}
""","""
"aaa" |
"bbb"
""")
    }

    private func assertTranspile(
        _ source: String,
        _ expected: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let result = try Reader().read(source: source)
        let swType = try XCTUnwrap(result.module.types.compactMap { $0.enum }.first)
        let tsType = try EnumConverter(
            converter: .init(typeMap: .default)
        ).transpile(type: swType)
        XCTAssertEqual(tsType.description, expected, file: file, line: line)
    }
}
