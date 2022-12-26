import XCTest
import CodableToTypeScript

final class GenerateRawRepresentableTests: GenerateTestCaseBase {
    func dateTypeMap() -> TypeMap {
        var typeMap = TypeMap()
        typeMap.table["Date"] = .coding(
            entityType: "Date", jsonType: "string",
            decode: "Date_decode", encode: "Date_encode"
        )
        return typeMap
    }

    func testStoredProperty() throws {
        try assertGenerate(
            source: """
struct S: RawRepresentable {
    var rawValue: String
}
""",
            expecteds: ["""
export type S = string & {
    S: never;
}
""", """
export type S_JSON = string;
""", """
export function S_decode(json: S_JSON): S {
    return json as S;
}
"""]
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
    return {
        a: S_decode(json.a)
    };
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
export type S = string & {
    S: never;
}
""", """
export type S_JSON = string;
""", """
export function S_decode(json: S_JSON): S {
    return json as S;
}
"""]
        )
    }

    func testOptional() throws {
        try assertGenerate(
            source: """
struct S: RawRepresentable {
    var rawValue: String?
}
""",
            expecteds: ["""
export type S = string & {
    S: never;
} | null;
""", """
export type S_JSON = string | null;
""", """
export function S_decode(json: S_JSON): S {
    return json as S;
}
"""]
        )
    }

    func testArray() throws {
        try assertGenerate(
            source: """
struct S: RawRepresentable {
    var rawValue: [String]
}
""",
            expecteds: ["""
export type S = string[] & {
    S: never;
}
""", """
export type S_JSON = string[];
""", """
export function S_decode(json: S_JSON): S {
    return json as S;
}
"""]
        )
    }

    func testStruct() throws {
        try assertGenerate(
            source: """
struct K {
    var a: Int
}

struct S: RawRepresentable {
    var rawValue: K
}
""",
            expecteds: ["""
export type S = K & {
    S: never;
};
""", """
export type S_JSON = K;
""", """
export function S_decode(json: S_JSON): S {
    return json as S;
}
"""]
        )
    }

    func testEnum() throws {
        try assertGenerate(
            source: """
enum E {
    case a(Int)
}

struct S: RawRepresentable {
    var rawValue: E
}
""",
            expecteds: ["""
export type S = E & {
    S: never;
};
""", """
export type S_JSON = E_JSON;
""", """
export function S_decode(json: S_JSON): S {
    return E_decode(json) as S;
}
"""
                       ],
            unexpecteds: ["""
export function S_encode
"""
                         ]
        )
    }

    func testEncodeStruct() throws {
        try assertGenerate(
            source: """
struct K {
    var a: Date
}

struct S: RawRepresentable {
    var rawValue: K
}
""",
            typeMap: dateTypeMap(),
            expecteds: ["""
export type S = K & {
    S: never;
};
""", """
export type S_JSON = K_JSON;
""", """
export function S_decode(json: S_JSON): S {
    return K_decode(json) as S;
}
""", """
export function S_encode(entity: S): S_JSON {
    return K_encode(entity) as S_JSON;
}
"""
                       ]
        )
    }

    func testMap() throws {
        try assertGenerate(
            source: """
struct S: RawRepresentable {
    var rawValue: Date
}
""",
            typeMap: dateTypeMap(),
            expecteds: ["""
export type S = Date & {
    S: never;
};
""", """
export type S_JSON = string;
""", """
export function S_decode(json: S_JSON): S {
    return Date_decode(json) as S;
}
""", """
export function S_encode(entity: S): S_JSON {
    return Date_encode(entity) as S_JSON;
}
"""
                       ]
        )
    }

    func testBoundGenericDecodeEncode() throws {
        try assertGenerate(
            source: """
struct K<T> {
    var a: T
}

struct S: RawRepresentable {
    var rawValue: K<Date>
}
""",
            typeMap: dateTypeMap(),
            expecteds: ["""
export type S = K<Date> & {
    S: never;
};
""", """
export type S_JSON = K_JSON<string>;
""", """
export function S_decode(json: S_JSON): S {
    return K_decode(json, Date_decode) as S;
}
""", """
export function S_encode(entity: S): S_JSON {
    return K_encode(entity, Date_encode) as S_JSON;
}
"""
                       ]
        )
    }

    func testBoundGenericDecodeOnly() throws {
        try assertGenerate(
            source: """
enum E { case a }

struct K<T> {
    var a: T
}

struct S: RawRepresentable {
    var rawValue: K<E>
}
""",
            expecteds: ["""
export type S = K<E> & {
    S: never;
};
""", """
export type S_JSON = K_JSON<E_JSON>;
""", """
export function S_decode(json: S_JSON): S {
    return K_decode(json, E_decode) as S;
}
"""
                       ],
            unexpecteds: ["""
export function S_encode
"""]
        )
    }

    func testBoundGenericIdentity() throws {
        try assertGenerate(
            source: """
struct K<T> {
    var a: T
}

struct S: RawRepresentable {
    var rawValue: K<Int>
}
""",
            expecteds: ["""
export type S = K<number> & {
    S: never;
};
""", """
export type S_JSON = K<number>;
""", """
export function S_decode(json: S_JSON): S {
    return json as S;
}
"""
                       ],
            unexpecteds: ["""
export function S_encode
"""]
        )
    }

    func testMapGeneric() throws {
        try assertGenerate(
            source: """
struct K<T> {
    var a: T
}

struct S<U>: RawRepresentable {
    var rawValue: K<U>
}
""",
            expecteds: ["""
export type S<U> = K<U> & {
    S: never;
};
""", """
export type S_JSON<U_JSON> = K_JSON<U_JSON>;
""", """
export function S_decode<U, U_JSON>(json: S_JSON<U_JSON>, U_decode: (json: U_JSON) => U): S<U> {
    return K_decode(json, U_decode) as S<U>;
}
""", """
export function S_encode<U, U_JSON>(entity: S<U>, U_encode: (entity: U) => U_JSON): S_JSON<U_JSON> {
    return K_encode(entity, U_encode) as S_JSON<U_JSON>;
}
"""
                       ]
        )
    }

    func testGenericParam() throws {
        try assertGenerate(
            source: """
struct S<T>: RawRepresentable {
    var rawValue: T
}
""",
            expecteds: ["""
export type S<T> = T & {
    S: never;
};
""", """
export type S_JSON<T_JSON> = T_JSON;
""", """
export function S_decode<T, T_JSON>(json: S_JSON<T_JSON>, T_decode: (json: T_JSON) => T): S<T> {
    return T_decode(json) as S<T>;
}
""", """
export function S_encode<T, T_JSON>(entity: S<T>, T_encode: (entity: T) => T_JSON): S_JSON<T_JSON> {
    return T_encode(entity) as S_JSON<T_JSON>;
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
export type K_JSON = {
    a: S_JSON<number>;
}
""", """
export function K_decode(json: K_JSON): K {
    return {
        a: S_decode(json.a, identity)
    };
}
"""],
            unexpecteds: ["""
export function K_encode
"""]
        )

    }

    func testNestedID() throws {
        try assertGenerate(
            source: """
struct User {
    struct ID {
        var rawValue: String
    }

    var id: ID
    var date: Date
}
""",
            typeMap: dateTypeMap(),
            expecteds: ["""
export type User_ID = string & {
    User_ID: never;
};
""", """
export type User_ID_JSON = string;
""", """
export function User_ID_decode(json: User_ID_JSON): User_ID {
    return json as User_ID;
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
    return {
        id: User_ID_decode(json.id),
        date: Date_decode(json.date)
    };
}
""", """
export function User_encode(entity: User): User_JSON {
    return {
        id: entity.id as User_ID_JSON,
        date: Date_encode(entity.date)
    };
}
"""
                       ],
            unexpecteds: ["""
export function User_ID_encode
"""]
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
export type ID<G> = string & {
    ID: never;
};
"""]
        )
    }
}
