import XCTest
import CodableToTypeScript

final class GenerateGenericTests: GenerateTestCaseBase {
    func testGenericStruct() throws {
        try assertGenerate(
            source: """
struct S<T> {
    var a: T
}
""",
            expecteds: ["""
export type S<T> = {
    a: T;
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
            typeSelector: .name("E"),
            expecteds: ["""
export type E<T> = {
    kind: "a";
    a: {
        _0: T;
    };
};
""","""
export type E_JSON<T> = {
    a: {
        _0: T;
    };
};
""","""
export function E_decode<T>(json: E_JSON<T>): E<T> {
    if ("a" in json) {
        const j = json.a;
        return {
            kind: "a",
            a: {
                _0: j._0
            }
        };
    } else {
        throw new Error("unknown kind");
    }
}
"""

            ]
        )
    }

}
