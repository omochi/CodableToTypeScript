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
export type E = ({
    kind: "a";
    a: {};
} | {
    kind: "b";
    b: {
        _0: number;
    };
}) & TagRecord<"E">;
""","""
export type E$JSON = {
    a: {};
} | {
    b: {
        _0: number;
    };
};
""","""
export function E_decode(json: E$JSON): E {
    if ("a" in json) {
        return {
            kind: "a",
            a: {}
        };
    } else if ("b" in json) {
        const j = json.b;
        const _0 = j._0;
        return {
            kind: "b",
            b: {
                _0: _0
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

    func testBasic2() throws {
        try assertGenerate(
            source: """
enum E {
    case a(x: Int)
    case b(y: String, Int)
}
""",
            expecteds: ["""
export type E = ({
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
}) & TagRecord<"E">;
""", """
export type E$JSON = {
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

    func testSingleCase() throws {
        try assertGenerate(
            source: """
enum E {
    case a
}
""",
            expecteds: ["""
export type E = {
    kind: "a";
    a: {};
} & TagRecord<"E">;
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
export type E = {
    kind: "a";
    a: {
        _0: number;
        _1?: number;
        _2?: number | null;
        _3?: number | null;
    };
} & TagRecord<"E">;
""", """
export type E$JSON = {
    a: {
        _0: number;
        _1?: number;
        _2?: number | null;
        _3?: number | null;
    };
};
""", """
export function E_decode(json: E$JSON): E {
    if ("a" in json) {
        const j = json.a;
        const _0 = j._0;
        const _1 = j._1;
        const _2 = j._2;
        const _3 = j._3;
        return {
            kind: "a",
            a: {
                _0: _0,
                _1: _1,
                _2: _2,
                _3: _3
            }
        };
    } else {
        throw new Error("unknown kind");
    }
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
        _0: {
            [key: string]: number;
        };
        _1: {
            [key: string]: number | null;
        };
    };
}
"""]
        )
    }

    func testStringRawValueCase() throws {
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
export type E = "a" |
"b" |
"c" |
"d"
"""]
        )
    }

    func testIntRawValueCase() throws {
        try assertGenerate(
            source: """
enum E: Int, Codable, Sendable {
    case a
    case b = -100
    case c
}
""",
            expecteds: ["""
export type E = "a" | "b" | "c";
""", """
export type E$JSON = 0 | -100 | -99;
""", """
export function E_decode(json: E$JSON): E {
    switch (json) {
    case 0:
        return "a";
    case -100:
        return "b";
    case -99:
        return "c";
    }
}
""", """
export function E_encode(entity: E): E$JSON {
    switch (entity) {
    case "a":
        return 0;
    case "b":
        return -100;
    case "c":
        return -99;
    }
}
"""]
        )
    }

    func testAssociatedValueDecode() throws {
        try assertGenerate(
            source: """
enum K {
    case a
}

struct S {
    var k: K
}

struct C {}

enum E {
    case k(K)
    case s(S)
    case c(C)
}
""",
            typeSelector: .name("E"),
            expecteds: ["""
export function E_decode(json: E$JSON): E {
    if ("k" in json) {
        const j = json.k;
        const _0 = K_decode(j._0);
        return {
            kind: "k",
            k: {
                _0: _0
            }
        };
    } else if ("s" in json) {
        const j = json.s;
        const _0 = S_decode(j._0);
        return {
            kind: "s",
            s: {
                _0: _0
            }
        };
    } else if ("c" in json) {
        const j = json.c;
        const _0 = j._0;
        return {
            kind: "c",
            c: {
                _0: _0
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

    func testConflictPropertyName() throws {
        try assertGenerate(
            source: """
enum E<T> {
    case entity(entity: String, json: String, e: String, j: String)
    case json
    case t(T)
}
""",
            expecteds: [
                // decode
"""
const json2 = j.json;
""", """
const j2 = j.j;
""", """
json: json2
""", """
j: j2
""",

// encode
"""
const entity2 = e.entity;
""", """
const e2 = e.e;
""", """
entity: entity2,
""", """
e: e2
"""
            ],
            unexpecteds: []
        )
    }
}
