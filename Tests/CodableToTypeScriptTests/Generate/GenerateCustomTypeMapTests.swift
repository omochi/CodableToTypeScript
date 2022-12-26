import XCTest
import CodableToTypeScript
import SwiftTypeReader
import TypeScriptAST

final class GenerateCustomTypeMapTests: GenerateTestCaseBase {
    func testCustomName() throws {
        var typeMap = TypeMap.default
        typeMap.table["URL"] = .identity(name: "string")

        try assertGenerate(
            source: """
struct S {
    var a: URL
    var b: [URL]
    var c: [[URL]]
}
""",
            typeMap: typeMap,
            expecteds: ["""
export type S = {
    a: string;
    b: string[];
    c: string[][];
} & TagRecord<"S">;
"""
                       ]
        )
    }

    func testCustomDecodeSimple() throws {
        var typeMap = TypeMap.default
        typeMap.table["Date"] = .coding(
            entityType: "Date", jsonType: "string",
            decode: "Date_decode", encode: nil
        )

        try assertGenerate(
            source: """
struct S {
    var a: Date
}
""",
            typeMap: typeMap,
            expecteds: ["""
export type S = {
    a: Date;
} & TagRecord<"S">;
""", """
export type S_JSON = {
    a: string;
};
""", """
export function S_decode(json: S_JSON): S {
    return {
        a: Date_decode(json.a)
    };
}
"""
                       ],
            unexpecteds: ["""
export function S_encode
"""]
        )
    }

    func testCustomDecodeComplex() throws {
        var typeMap = TypeMap.default
        typeMap.table["Date"] = .coding(
            entityType: "Date", jsonType: "string",
            decode: "Date_decode", encode: nil
        )

        try assertGenerate(
            source: """
struct S {
    var a: Date
    var b: [Date]
    var c: [[Date]]
}
""",
            typeMap: typeMap,
            expecteds: ["""
export type S = {
    a: Date;
    b: Date[];
    c: Date[][];
} & TagRecord<"S">;
""", """
export type S_JSON = {
    a: string;
    b: string[];
    c: string[][];
};
""", """
export function S_decode(json: S_JSON): S {
    return {
        a: Date_decode(json.a),
        b: Array_decode(json.b, Date_decode),
        c: Array_decode(json.c, (json: string[]): Date[] => {
            return Array_decode(json, Date_decode);
        })
    };
}
"""
                       ]
        )
    }

    func testCustomEncode() throws {
        var typeMap = TypeMap.default
        typeMap.table["Date"] = .coding(
            entityType: "Date", jsonType: "string",
            decode: nil, encode: "Date_encode"
        )

        try assertGenerate(
            source: """
struct S {
    var a: Date
}
""",
            typeMap: typeMap,
            expecteds: ["""
export type S = {
    a: Date;
} & TagRecord<"S">;
""", """
export type S_JSON = {
    a: string;
};
""", """
export function S_encode(entity: S): S_JSON {
    return {
        a: Date_encode(entity.a)
    };
}
"""
                       ],
            unexpecteds: ["""
export function S_decode
"""]
        )
    }

    func testCustomCoding() throws {
        var typeMap = TypeMap.default
        typeMap.table["Date"] = .coding(
            entityType: "Date", jsonType: "string",
            decode: "Date_decode", encode: "Date_encode"
        )

        try assertGenerate(
            source: """
struct S {
    var a: Date
}
""",
            typeMap: typeMap,
            expecteds: ["""
import { Date_decode, Date_encode, TagRecord }
""", """
export type S = {
    a: Date;
} & TagRecord<"S">;
""", """
export type S_JSON = {
    a: string;
};
""", """
export function S_decode(json: S_JSON): S {
    return {
        a: Date_decode(json.a)
    };
}
""", """
export function S_encode(entity: S): S_JSON {
    return {
        a: Date_encode(entity.a)
    };
}
"""
                       ]
        )
    }

    func testCustomGenericDecode() throws {
        var typeMap = TypeMap.default
        typeMap.table["Date"] = .coding(
            entityType: "Date", jsonType: "string",
            decode: "Date_decode", encode: "Date_encode"
        )
        typeMap.table["Vector2"] = .coding(
            entityType: "Vector2", jsonType: "Vector2_JSON",
            decode: "Vector2_decode", encode: "Vector2_encode"
        )

        try assertGenerate(
            source: """
struct S {
    var a: Vector2<Float>
    var b: Vector2<Date>
    var c: [Vector2<Vector2<Float>>]
}
""",
            typeMap: typeMap,
            expecteds: ["""
export type S = {
    a: Vector2<number>;
    b: Vector2<Date>;
    c: Vector2<Vector2<number>>[];
} & TagRecord<"S">;
""", """
export type S_JSON = {
    a: Vector2_JSON<number>;
    b: Vector2_JSON<string>;
    c: Vector2_JSON<Vector2_JSON<number>>[];
};
""", """
export function S_decode(json: S_JSON): S {
    return {
        a: Vector2_decode(json.a, identity),
        b: Vector2_decode(json.b, Date_decode),
        c: Array_decode(json.c, (json: Vector2_JSON<Vector2_JSON<number>>): Vector2<Vector2<number>> => {
            return Vector2_decode(json, (json: Vector2_JSON<number>): Vector2<number> => {
                return Vector2_decode(json, identity);
            });
        })
    };
}
"""
                       ]
        )
    }

    func testCustomIDDecode() throws {
        var typeMap = TypeMap.default
        typeMap.mapFunction = { (type) in
            let repr = type.toTypeRepr(containsModule: false)
            guard let repr = repr.asIdent,
                  let element = repr.elements.last else { return nil }
            if element.name.hasSuffix("ID") {
                return .identity(name: "string")
            }
            return nil
        }

        try assertGenerate(
            source: """
struct S {
    var a: UserID
    var b: [UserID]
    var c: [[UserID]]
}
""",
            typeMap: typeMap,
            expecteds: ["""
export type S = {
    a: string;
    b: string[];
    c: string[][];
} & TagRecord<"S">;
"""
                       ]
        )
    }

    func testMapUserType() throws {
        var typeMap = TypeMap()
        typeMap.table["S"] = .identity(name: "V")
        try assertGenerate(
            source: """
struct S {
    var a: Int
}
""",
            typeMap: typeMap,
            unexpecteds: ["""
export type S
"""
            ]
        )
    }

    func testMapUserTypeCodec() throws {
        var typeMap = TypeMap()
        typeMap.table["S"] = .coding(
            entityType: "V", jsonType: "V_JSON",
            decode: "V_decode", encode: "V_encode"
        )
        try assertGenerate(
            source: """
struct S {
    var a: Int
}
""",
            typeMap: typeMap,
            unexpecteds: ["""
export type S
"""
            ]
        )
    }

    func testMapNestedUserType() throws {
        var typeMap = TypeMap()
        typeMap.table["K"] = .identity(name: "V")
        try assertGenerate(
            source: """
struct S {
    struct K {
    }
    var a: Int
}
""",
            typeMap: typeMap,
            expecteds: ["""
export type S
"""],
            unexpecteds: ["""
export type S_K
"""]
        )
    }
}
