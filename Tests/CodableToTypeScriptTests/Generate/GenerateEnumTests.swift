import XCTest
import CodableToTypeScript

final class GenerateEnumTests: GenerateTestCaseBase {
    func testBasic1() throws {
        try assertGenerate(
            source: """
enum E {
    case a
    case b(Int)
}
""",
            expecteds: ["""
export type E = {
    kind: "a";
    a: {};
} | {
    kind: "b";
    b: {
        _0: number;
    };
};
""","""
export type E_JSON = {
    a: {};
} | {
    b: {
        _0: number;
    };
};
""","""
export function E_decode(json: E_JSON): E {
    if ("a" in json) {
        return { "kind": "a", a: json.a };
    } else if ("b" in json) {
        return { "kind": "b", b: json.b };
    } else {
        throw new Error("unknown kind");
    }
}
"""
            ]
        )
    }

    func testBasic2() throws {
        try assertGenerate(
            source: """
enum E {
    case a(x: Int)
    case b(y: String, Int)
}
""",
            expecteds: ["""
export type E = {
    kind: "a";
    a: {
        x: number;
    };
} | {
    kind: "b";
    b: {
        y: string;
        _1: number;
    };
}
""", """
export type E_JSON = {
    a: {
        x: number;
    };
} | {
    b: {
        y: string;
        _1: number;
    };
}
"""]
        )
    }

    func testOptional() throws {
        try assertGenerate(
            source: """
enum E {
    case a(Int, Int?, Int??, Int???)
}
""",
            expecteds: ["""
{
    a: {
        _0: number;
        _1?: number;
        _2?: number | null;
        _3?: number | null;
    };
}
"""]
        )
    }

    func testArray() throws {
        try assertGenerate(
            source: """
enum E {
    case a([Int], [[Int]], [Int]?, [Int?])
}
""",
            expecteds: ["""
{
    a: {
        _0: number[];
        _1: number[][];
        _2?: number[];
        _3: (number | null)[];
    };
}
"""]
        )
    }

    func testDictionary() throws {
        try assertGenerate(
            source: """
enum E {
    case a([String: Int], [String: Int?])
}
""",
            expecteds: [
"""
{
    a: {
        _0: { [key: string]: number; };
        _1: { [key: string]: number | null; };
    };
}
"""]
        )
    }

    func testStringRawValue4Case() throws {
        try assertGenerate(
            source: """
enum E: String {
    case a
    case b
}
""",
            expecteds: ["""
export type E = "a" | "b"
"""]
        )

        try assertGenerate(
            source: """
enum E: String {
    case a
    case b
    case c
}
""",
            expecteds: ["""
export type E = "a" | "b" | "c"
"""]
        )

        try assertGenerate(
            source: """
enum E: String {
    case a
    case b
    case c
    case d
}
""",
            expecteds: ["""
export type E = "a" | "b" | "c" |
"d"
"""]
        )
    }
}
