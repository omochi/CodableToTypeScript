import XCTest
import CodableToTypeScript
import SwiftTypeReader
import TypeScriptAST

final class GenerateCustomTypeMapTests: GenerateTestCaseBase {
    func testCustomName() throws {
        var typeMap = TypeMap.default
        typeMap.table["URL"] = .init(name: "string")

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
};
"""
                       ]
        )
    }

    func testCustomDecodeSimple() throws {
        var typeMap = TypeMap.default
        typeMap.table["Date"] = .init(name: "Date", decode: "Date_decode")

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
};
""", """
export type S_JSON = {
    a: Date_JSON;
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
        typeMap.table["Date"] = .init(name: "Date", decode: "Date_decode")

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
};
""", """
export type S_JSON = {
    a: Date_JSON;
    b: Date_JSON[];
    c: Date_JSON[][];
};
""", """
export function S_decode(json: S_JSON): S {
    return {
        a: Date_decode(json.a),
        b: Array_decode(json.b, Date_decode),
        c: Array_decode(json.c, (json: Date_JSON[]): Date[] => {
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
        typeMap.table["Date"] = .init(name: "Date", encode: "Date_encode")

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
};
""", """
export type S_JSON = {
    a: Date_JSON;
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
        typeMap.table["Date"] = .init(
            name: "Date",
            jsonType: "string",
            decode: "Date_decode",
            encode: "Date_encode"
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
};
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
""", """
import { Date_decode, Date_encode }
"""
                       ]
        )
    }

    func testCustomGenericDecode() throws {
        var typeMap = TypeMap.default
        typeMap.table["Date"] = .init(name: "Date", decode: "Date_decode")
        typeMap.table["Vector2"] = .init(name: "Vector2", decode: "Vector2_decode")

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
};
""", """
export type S_JSON = {
    a: Vector2_JSON<number>;
    b: Vector2_JSON<Date_JSON>;
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
                return .init(name: "string")
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
};
"""
                       ]
        )
    }

    func testMapUserType() throws {
        var typeMap = TypeMap()
        typeMap.table["S"] = .init(name: "V")
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
        typeMap.table["S"] = .init(name: "V", decode: "V_decode", encode: "V_encode")
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
        typeMap.table["K"] = .init(name: "V")
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
