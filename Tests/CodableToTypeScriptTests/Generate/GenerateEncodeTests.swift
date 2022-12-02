import XCTest
import CodableToTypeScript

final class GenerateEncodeTests: GenerateTestCaseBase {
    func dateTypeMap() -> TypeMap {
        var typeMap = TypeMap()
        typeMap.table["Date"] = .init(name: "Date", decode: "Date_decode", encode: "Date_encode")
        return typeMap
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
            expecteds: ["""
export type E = {
    kind: "a";
    a: {};
} | {
    kind: "b";
    b: {
        _0: Date;
    };
};
""", """
export type E_JSON = {
    a: {};
} | {
    b: {
        _0: Date_JSON;
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
            expecteds: ["""
export type S = {
    a: Date;
    b?: Date;
    c?: Date | null;
    d: Date[];
};
""", """
export type S_JSON = {
    a: Date_JSON;
    b?: Date_JSON;
    c?: Date_JSON | null;
    d: Date_JSON[];
};
""", """
export function S_encode(entity: S): S_JSON {
    return {
        a: Date_encode(entity.a),
        b: OptionalField_encode(entity.b, Date_encode),
        c: OptionalField_encode(entity.c, (entity: Date | null): Date_JSON | null => {
            return Optional_encode(entity, Date_encode);
        }),
        d: Array_encode(entity.d, Date_encode)
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
            expecteds: ["""
export function S_encode(entity: S): S_JSON {
    return {
        a: entity.a as E_JSON,
        b: Date_encode(entity.b)
    };
}
"""
            ]
        )


    }
}
