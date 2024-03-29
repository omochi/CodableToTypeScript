import XCTest
import TestUtils
import CodableToTypeScript
import SwiftTypeReader

final class GenerateExampleTests: GenerateTestCaseBase {
    func testStruct() throws {
        try assertGenerate(
            source: """
struct S {
    var x: Int
    var o1: Int?
    var o2: Int??
    var o3: Int???
    var a1: [Int?]
    var d1: [String: Int]
}
""",
            expecteds: ["""
export type S = {
    x: number;
    o1?: number;
    o2?: number | null;
    o3?: number | null;
    a1: (number | null)[];
    d1: Map<string, number>;
} & TagRecord<"S">;
"""]
        )
    }

    func testEnum() throws {
        try assertGenerate(
            source: """
enum E {
    case a(x: Int, y: Int)
    case b([String])
""",
            expecteds: ["""
export type E = ({
    kind: "a";
    a: {
        x: number;
        y: number;
    };
} | {
    kind: "b";
    b: {
        _0: string[];
    };
}) & TagRecord<"E">;
""", """
export type E_JSON = {
    a: {
        x: number;
        y: number;
    };
} | {
    b: {
        _0: string[];
    };
};
""", """
export function E_decode(json: E_JSON): E {
    if ("a" in json) {
        const j = json.a;
        const x = j.x;
        const y = j.y;
        return {
            kind: "a",
            a: {
                x: x,
                y: y
            }
        };
    } else if ("b" in json) {
        const j = json.b;
        const _0 = j._0 as string[];
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
"""])
    }

    func testEnumInStruct() throws {
        try assertGenerate(
            source: """
enum E1 {
    case a
}

enum E2: String {
    case a
}

struct S {
    var x: E1
    var y: E2
}
""",
            expecteds: ["""
import {
    E1,
    E1_JSON,
    E1_decode,
    E2,
    TagRecord
} from "..";
""", """
export type S = {
    x: E1;
    y: E2;
} & TagRecord<"S">;
""", """
export type S_JSON = {
    x: E1_JSON;
    y: E2;
};
""", """
export function S_decode(json: S_JSON): S {
    const x = E1_decode(json.x);
    const y = json.y;
    return {
        x: x,
        y: y
    };
}
"""]
        )
    }

    func testGenericResponse() throws {
        try assertGenerate(
            source: """
enum E {
    case a
    case b
}

enum R<T> {
    case s(T)
    case f(E)
}
""",
        expecteds: ["""
import {
    E,
    E_JSON,
    E_decode,
    TagRecord
} from "..";
""", """
export type R<T> = ({
    kind: "s";
    s: {
        _0: T;
    };
} | {
    kind: "f";
    f: {
        _0: E;
    };
}) & TagRecord<"R", [T]>;
""", """
export type R_JSON<T_JSON> = {
    s: {
        _0: T_JSON;
    };
} | {
    f: {
        _0: E_JSON;
    };
};
""", """
export function R_decode<T, T_JSON>(json: R_JSON<T_JSON>, T_decode: (json: T_JSON) => T): R<T> {
    if ("s" in json) {
        const j = json.s;
        const _0 = T_decode(j._0);
        return {
            kind: "s",
            s: {
                _0: _0
            }
        };
    } else if ("f" in json) {
        const j = json.f;
        const _0 = E_decode(j._0);
        return {
            kind: "f",
            f: {
                _0: _0
            }
        };
    } else {
        throw new Error("unknown kind");
    }
}
"""]
        )
    }

    func testNestedType() throws {
        try assertGenerate(
            source: """
enum E { case a }

struct S {
    struct K {
        var a: E
    }

    var a: D
    var b: K
}
""",
            typeMap: TypeMap { (type) in
                let repr = type.toTypeRepr(containsModule: false)

                if let ident = repr.asIdent,
                   ident.elements.last?.name == "D"
                {
                    return .identity(name: "string")
                }

                return nil
            },
            expecteds: ["""
export type S = {
    a: string;
    b: S_K;
} & TagRecord<"S">;
""", """
export type S_JSON = {
    a: string;
    b: S_K_JSON;
};
""", """
export function S_decode(json: S_JSON): S {
    const a = json.a;
    const b = S_K_decode(json.b);
    return {
        a: a,
        b: b
    };
}
""", """
export type S_K = {
    a: E;
} & TagRecord<"S_K">;
""", """
export type S_K_JSON = {
    a: E_JSON;
};
""", """
export function S_K_decode(json: S_K_JSON): S_K {
    const a = E_decode(json.a);
    return {
        a: a
    };
}
"""
            ]
        )
    }
}
