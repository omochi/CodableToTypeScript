import XCTest
@testable import CodableToTypeScript
import SwiftTypeReader

final class GenerateTests: XCTestCase {
    func testGenericStruct() throws {
        try assertGenerate(
            source: """
struct S<T> {
    var a: T
}
""",
            type: "S",
            expecteds: ["""
export type S<T> = {
    a: T;
};
"""]
        )
    }

    func testChildEnum() throws {
        try assertGenerate(
            source: """
enum E {
    case a
}

struct S {
    var a: E
}
""",
            type: "S",
            expecteds: ["""
export type S = {
    a: EJSON;
};
"""]
        )
    }

    func testGenericArguments() throws {
        try assertGenerate(
            source: """
struct S1<T> {
    var a: S2<T>
}
""",
            type: "S1",
            expecteds: ["""
export type S1<T> = {
    a: S2<T>;
};
"""]
        )
    }

    func testGenericEnum() throws {
        try assertGenerate(
            source: """
enum E<T> {
    case a(T)
}
""",
            type: "E",
            expecteds: [
                """
export type EJSON<T> = {
    a: {
        _0: T;
    };
};
""",
                """
export type E<T> = {
    kind: "a";
    a: {
        _0: T;
    };
};
""",
                """
export function EDecode<T>(json: EJSON<T>): E<T>
"""

            ]
        )
    }

    func testStringRawValueEnum() throws {
        try assertGenerate(
            source: """
enum E: String, Codable {
    case aaa
    case iii
}
""",
            type: "E",
            expecteds: [
                """
export type E = "aaa" |
"iii";
""",
            ]
        )
    }

    private func assertGenerate(
        source: String,
        type: String,
        expecteds: [String],
        file: StaticString = #file, line: UInt = #line
    ) throws {
        let tsCode = try Utils.generate(
            source: source,
            type: { $0.name == type },
            file: file, line: line
        )
        let actual = tsCode.description
        for expected in expecteds {
            if !actual.contains(expected) {
                XCTFail("\(actual) does not contain \(expected)")
            }
        }
    }
}
