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
            expecteds: ["""
export type S = {
    a: number;
    b: string;
};
""", """
export type S_JSON = {
    a: number;
    b: string;
};
""", """
export function S_decode(json: S_JSON): S {
    return {
        a: json.a,
        b: json.b
    };
}
"""
            ]
        )
    }

    func testEnumInStruct() throws {
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

    func testDecodeOptional() throws {
        try assertGenerate(
            source: """
enum E { case a }

struct S {
    var e1: E?
    var e2: E??
    var e3: E???
}
""",
            typeSelector: .name("S"),
            expecteds: ["""
export type S = {
    e1?: E;
    e2?: E | null;
    e3?: E | null;
};
""", """
export type S_JSON = {
    e1?: E_JSON;
    e2?: E_JSON | null;
    e3?: E_JSON | null;
};
""", """
export function S_decode(json: S_JSON): S {
    return {
        e1: OptionalField_decode(json.e1, E_decode),
        e2: OptionalField_decode(json.e2, (json: E_JSON | null): E | null => {
            return Optional_decode(json, E_decode);
        }),
        e3: OptionalField_decode(json.e3, (json: E_JSON | null): E | null => {
            return Optional_decode(json, E_decode);
        })
    };
}
"""
            ]
        )
    }
}
