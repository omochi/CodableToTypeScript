import XCTest
import CodableToTypeScript

final class GenerateStructTests: GenerateTestCaseBase {
    func testSimple() throws {
        try assertGenerate(
            source: """
struct S {
    var a: Int
    var b: String
}
""",
            unexpecteds: ["""
export type S_JSON
"""
            ]
        )
    }

    func testHavingEnum() throws {
        try assertGenerate(
            source: """
enum E {
    case a
}

struct S {
    var a: Int
    var b: E
}
""",
            typeSelector: .name("S"),
            expecteds: ["""
export type S = {
    a: number;
    b: E;
};
""", """
export type S_JSON = {
    a: number;
    b: E_JSON;
};
""", """
export function S_decode(json: S_JSON): S {
    return {
        a: json.a,
        b: E_decode(json.b)
    };
}
"""]
        )
    }
}
