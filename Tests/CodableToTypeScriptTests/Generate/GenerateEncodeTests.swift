import XCTest
import CodableToTypeScript

final class GenerateEncodeTests: GenerateTestCaseBase {
    func dateTypeMap() -> TypeMap {
        var typeMap = TypeMap()
        typeMap.table["Date"] = .coding(
            entityType: "Date", jsonType: "string",
            decode: "Date_decode", encode: "Date_encode"
        )
        return typeMap
    }

    func dateTypeExternal() -> ExternalReference {
        return ExternalReference(
            code: """
            export function Date_decode(json: string): Date { throw 0; }
            export function Date_encode(date: Date): string { throw 0; }
            """
        )
    }

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
export type E_JSON = {
    a: {};
} | {
    b: {
        _0: string;
    };
};
""", """
export function E_encode(entity: E): E_JSON {
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
            return {
                b: {
                    _0: Date_encode(e._0)
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
export type S_JSON = {
    a: string;
    b?: string;
    c?: string | null;
    d: string[];
};
""", """
export function S_encode(entity: S): S_JSON {
    const a = Date_encode(entity.a);
    const b = OptionalField_encode(entity.b, Date_encode);
    const c = OptionalField_encode(entity.c, (entity: Date | null): string | null => {
        return Optional_encode(entity, Date_encode);
    });
    const d = Array_encode(entity.d, Date_encode);
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
export function S_encode(entity: S): S_JSON {
    const a = entity.a as E_JSON;
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
}
