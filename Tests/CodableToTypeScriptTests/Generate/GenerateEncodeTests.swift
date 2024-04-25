import XCTest
import CodableToTypeScript

final class GenerateEncodeTests: GenerateTestCaseBase {
    func testEnum() throws {
        try assertGenerate(
            source: """
enum E {
    case a
    case b(Date)
}
""",
            typeMap: dateTypeMap(),
            externalReference: dateTypeExternal(),
            expecteds: ["""
export type E = ({
    kind: "a";
    a: {};
} | {
    kind: "b";
    b: {
        _0: Date;
    };
}) & TagRecord<"E">;
""", """
export type E$JSON = {
    a: {};
} | {
    b: {
        _0: string;
    };
};
""", """
export function E_encode(entity: E): E$JSON {
    switch (entity.kind) {
    case "a":
        {
            return {
                a: {}
            };
        }
    case "b":
        {
            const e = entity.b;
            const _0 = Date_encode(e._0);
            return {
                b: {
                    _0: _0
                }
            };
        }
    default:
        const check: never = entity;
        throw new Error("invalid case: " + check);
    }
}
"""]
        )
    }

    func testStruct() throws {
        try assertGenerate(
            source: """
struct S {
    var a: Date
    var b: Date?
    var c: Date??
    var d: [Date]
}
""",
            typeMap: dateTypeMap(),
            externalReference: dateTypeExternal(),
            expecteds: ["""
export type S = {
    a: Date;
    b?: Date;
    c?: Date | null;
    d: Date[];
} & TagRecord<"S">;
""", """
export type S$JSON = {
    a: string;
    b?: string;
    c?: string | null;
    d: string[];
};
""", """
export function S_encode(entity: S): S$JSON {
    const a = Date_encode(entity.a);
    const b = OptionalField_encode<Date, string>(entity.b, Date_encode);
    const c = OptionalField_encode<Date | null, string | null>(entity.c, (entity: Date | null): string | null => {
        return Optional_encode<Date, string>(entity, Date_encode);
    });
    const d = Array_encode<Date, string>(entity.d, Date_encode);
    return {
        a: a,
        b: b,
        c: c,
        d: d
    };
}
"""]
        )
    }

    func testAsOperatorIdentityEncode() throws {
        try assertGenerate(
            source: """
enum E {
    case a(Int)
}

struct S {
    var a: E
    var b: Date
}
""",
            typeMap: dateTypeMap(),
            externalReference: dateTypeExternal(),
            expecteds: ["""
export function S_encode(entity: S): S$JSON {
    const a = entity.a as E$JSON;
    const b = Date_encode(entity.b);
    return {
        a: a,
        b: b
    };
}
"""
            ]
        )
    }

    func testVariableNameEscaping() throws {
        try assertGenerate(
            source: """
struct S<T> {
    var `class`: T
}
""",
            expecteds: ["""
export function S_decode<T, T$JSON>(json: S$JSON<T$JSON>, T_decode: (json: T$JSON) => T): S<T> {
    const _class = T_decode(json.class);
    return {
        class: _class
    };
}
""", """
export function S_encode<T, T$JSON>(entity: S<T>, T_encode: (entity: T) => T$JSON): S$JSON<T$JSON> {
    const _class = T_encode(entity.class);
    return {
        class: _class
    };
}
"""]
        )

            try assertGenerate(
                source: """
enum E<T> {
    case `class`(break: T)
}
""",
                expecteds: ["""
export function E_decode<T, T$JSON>(json: E$JSON<T$JSON>, T_decode: (json: T$JSON) => T): E<T> {
    if ("class" in json) {
        const j = json.class;
        const _break = T_decode(j.break);
        return {
            kind: "class",
            class: {
                break: _break
            }
        };
    } else {
        throw new Error("unknown kind");
    }
}
""", """
export function E_encode<T, T$JSON>(entity: E<T>, T_encode: (entity: T) => T$JSON): E$JSON<T$JSON> {
    const e = entity.class;
    const _break = T_encode(e.break);
    return {
        class: {
            break: _break
        }
    };
}
"""]
        )
    }
}
