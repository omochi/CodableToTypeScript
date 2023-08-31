import XCTest
import CodableToTypeScript

final class GenerateRawRepresentableTests: GenerateTestCaseBase {
    func testStoredProperty() throws {
        try assertGenerate(
            source: """
struct S: RawRepresentable {
    var rawValue: String
}
""",
            expecteds: ["""
export type S = {
    rawValue: string;
} & TagRecord<"S">;
""", """
export type S_JSON = string;
""", """
export function S_decode(json: S_JSON): S {
    return {
        rawValue: json
    };
}
""", """
export function S_encode(entity: S): S_JSON {
    return entity.rawValue;
}
"""
                       ]
        )
    }

    func testUseStoredProperty() throws {
        try assertGenerate(
            source: """
struct S: RawRepresentable {
    var rawValue: String
}

struct K {
    var a: S
}
""",
            expecteds: ["""
export type K = {
    a: S;
}
""", """
export type K_JSON = {
    a: S_JSON;
};
""", """
export function K_decode(json: K_JSON): K {
    const a = S_decode(json.a);
    return {
        a: a
    };
}
""", """
export function K_encode(entity: K): K_JSON {
    const a = S_encode(entity.a);
    return {
        a: a
    };
}
"""
                       ]
        )
    }

    func testTypeAlias() throws {
        try assertGenerate(
            source: """
struct S: RawRepresentable {
    typealias RawValue = Int
    var rawValue: RawValue
}
""",
            expecteds: ["""
export type S_RawValue = number;
""", """
export type S = {
    rawValue: number;
} & TagRecord<"S">;
""", """
export type S_JSON = number;
""", """
export function S_decode(json: S_JSON): S {
    return {
        rawValue: json
    };
}
""", """
export function S_encode(entity: S): S_JSON {
    return entity.rawValue;
}
"""
                       ]
        )
    }

    func testComputedProperty() throws {
        try assertGenerate(
            source: """
struct S: RawRepresentable {
    var rawValue: String { "s" }
}
""",
            expecteds: ["""
export type S = {
    rawValue: string;
} & TagRecord<"S">;
""", """
export type S_JSON = string;
""", """
export function S_decode(json: S_JSON): S {
    return {
        rawValue: json
    };
}
""", """
export function S_encode(entity: S): S_JSON {
    return entity.rawValue;
}
"""
                       ]
        )
    }

    func testOptional() throws {
        try assertGenerate(
            source: """
struct S: RawRepresentable {
    var rawValue: Int?
}
""",
        expecteds: ["""
export type S = {
    rawValue?: number;
} & TagRecord<"S">;
"""
        ])
    }

    func testGenericParam() throws {
        try assertGenerate(
            source: """
struct S<T>: RawRepresentable {
    var rawValue: T
}
""",
            expecteds: ["""
export type S<T> = {
    rawValue: T;
} & TagRecord<"S", [T]>;
""", """
export type S_JSON<T_JSON> = {
    rawValue: T_JSON;
};
""", """
export function S_decode<T, T_JSON>(json: S_JSON<T_JSON>, T_decode: (json: T_JSON) => T): S<T> {
    const rawValue = T_decode(json.rawValue);
    return {
        rawValue: rawValue
    };
}
""", """
export function S_encode<T, T_JSON>(entity: S<T>, T_encode: (entity: T) => T_JSON): S_JSON<T_JSON> {
    const rawValue = T_encode(entity.rawValue);
    return {
        rawValue: rawValue
    };
}
"""
                   ]
        )
    }

    func testGenericParamApplyIdentity() throws {
        try assertGenerate(
            source: """
struct S<T>: RawRepresentable {
    var rawValue: T
}

struct K {
    var a: S<Int>
}
""",
            expecteds: ["""
export type K = {
    a: S<number>;
}
""", """
export type K_JSON = {
    a: number;
}
""", """
export function K_decode(json: K_JSON): K {
    const a = {
        rawValue: json.a
    };
    return {
        a: a
    };
}
""", """
export function K_encode(entity: K): K_JSON {
    const a = entity.a.rawValue;
    return {
        a: a
    };
}
"""
                       ]
        )
    }

    func testNestedID() throws {
        try assertGenerate(
            source: """
struct User {
    struct ID: RawRepresentable {
        var rawValue: String
    }

    var id: ID
    var date: Date
}
""",
            typeMap: dateTypeMap(),
            externalReference: dateTypeExternal(),
            expecteds: ["""
export type User_ID = {
    rawValue: string;
} & TagRecord<"User_ID">;
""", """
export type User_ID_JSON = string;
""", """
export function User_ID_decode(json: User_ID_JSON): User_ID {
    return {
        rawValue: json
    };
}
""", """
export function User_ID_encode(entity: User_ID): User_ID_JSON {
    return entity.rawValue;
}
""", """
export type User = {
    id: User_ID;
    date: Date;
} & TagRecord<"User">;
""", """
export type User_JSON = {
    id: User_ID_JSON;
    date: string;
};
""", """
export function User_decode(json: User_JSON): User {
    const id = User_ID_decode(json.id);
    const date = Date_decode(json.date);
    return {
        id: id,
        date: date
    };
}
""", """
export function User_encode(entity: User): User_JSON {
    const id = User_ID_encode(entity.id);
    const date = Date_encode(entity.date);
    return {
        id: id,
        date: date
    };
}
"""
                       ]
        )
    }

    func testPhantomString() throws {
        try assertGenerate(
            source: """
struct ID<G>: RawRepresentable {
    var rawValue: String
}
""",
            expecteds: ["""
export type ID<G> = {
    rawValue: string;
} & TagRecord<"ID", [G]>;
""", """
export type ID_JSON<G_JSON> = string;
"""]
        )
    }
}
