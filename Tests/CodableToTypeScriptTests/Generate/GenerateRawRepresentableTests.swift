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

    private let rawValueTransferCodingProvider: TypeConverterProvider.CustomProvider = { (generator, stype) in
        if let `struct` = stype.asStruct,
           let rawValueType = `struct`.rawValueType(checkRawRepresentableCodingType: false) {
            return try? RawValueTransferringConverter(generator: generator, swiftType: stype, rawValueType: rawValueType)
        }
        return nil
    }

    func testOptionalComplex() throws {
        try assertGenerate(
            source: """
struct K: RawRepresentable {
    var rawValue: Int
}

struct S: RawRepresentable {
    var rawValue: K?
}
""",
            typeConverterProvider: .init(customProvider: rawValueTransferCodingProvider),
            expecteds: ["""
export type S = {
    rawValue?: K;
} & TagRecord<"S">;
""", """
export type S_JSON = K_JSON | null;
""", """
export function S_decode(json: S_JSON): S {
    return {
        rawValue: Optional_decode<K, K_JSON>(json, K_decode) ?? undefined
    };
}
""", """
export function S_encode(entity: S): S_JSON {
    return OptionalField_encode<K, K_JSON>(entity.rawValue, K_encode) ?? null;
}
"""
       ])
    }

    func testDoubleOptional() throws {
        try assertGenerate(
            source: """
struct S: RawRepresentable {
    var rawValue: Int??
}
""",
            typeConverterProvider: .init(customProvider: rawValueTransferCodingProvider),
            expecteds: ["""
export type S = {
    rawValue?: number | null;
} & TagRecord<"S">;
""", """
export type S_JSON = number | null;
""", """
export function S_decode(json: S_JSON): S {
    return {
        rawValue: json as number | null ?? undefined
    };
}
""", """
export function S_encode(entity: S): S_JSON {
    return entity.rawValue ?? null;
}
"""
       ])
    }

    func testDoubleOptionalComplex() throws {
        try assertGenerate(
            source: """
struct K: RawRepresentable {
    var rawValue: Int
}

struct S: RawRepresentable {
    var rawValue: K??
}
""",
            typeConverterProvider: .init(customProvider: rawValueTransferCodingProvider),
            expecteds: ["""
export type S = {
    rawValue?: K | null;
} & TagRecord<"S">;
""", """
export type S_JSON = K_JSON | null;
""", """
export function S_decode(json: S_JSON): S {
    return {
        rawValue: Optional_decode<K, K_JSON>(json, K_decode) ?? undefined
    };
}
""", """
export function S_encode(entity: S): S_JSON {
    return OptionalField_encode<K | null, K_JSON | null>(entity.rawValue, (entity: K | null): K_JSON | null => {
        return Optional_encode<K, K_JSON>(entity, K_encode);
    }) ?? null;
}
"""
                       ])
    }

    func testArray() throws {
        try assertGenerate(
            source: """
struct S: RawRepresentable {
    var rawValue: [String]
}
""",
            typeConverterProvider: .init(customProvider: rawValueTransferCodingProvider),
            expecteds: ["""
export type S = {
    rawValue: string[];
} & TagRecord<"S">;
""", """
export type S_JSON = string[];
""", """
export function S_decode(json: S_JSON): S {
    return {
        rawValue: json as string[]
    };
}
""", """
export function S_encode(entity: S): S_JSON {
    return entity.rawValue as string[];
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
            typeConverterProvider: .init(customProvider: rawValueTransferCodingProvider),
            expecteds: ["""
export type S = {
    rawValue: K;
} & TagRecord<"S">;
""", """
export type S_JSON = K;
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
            typeConverterProvider: .init(customProvider: rawValueTransferCodingProvider),
            expecteds: ["""
export type S = {
    rawValue: E;
} & TagRecord<"S">;
""", """
export type S_JSON = E_JSON;
""", """
export function S_decode(json: S_JSON): S {
    return {
        rawValue: E_decode(json)
    };
}
""", """
export function S_encode(entity: S): S_JSON {
    return entity.rawValue as E_JSON;
}
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
            typeConverterProvider: .init(typeMap: dateTypeMap(), customProvider: rawValueTransferCodingProvider),
            externalReference: dateTypeExternal(),
            expecteds: ["""
export type S = {
    rawValue: K;
} & TagRecord<"S">;
""", """
export type S_JSON = K_JSON;
""", """
export function S_decode(json: S_JSON): S {
    return {
        rawValue: K_decode(json)
    };
}
""", """
export function S_encode(entity: S): S_JSON {
    return K_encode(entity.rawValue);
}
"""
                       ]
        )
    }

    func testCustomMap() throws {
        try assertGenerate(
            source: """
struct S: RawRepresentable {
    var rawValue: Date
}
""",
            typeConverterProvider: .init(typeMap: dateTypeMap(), customProvider: rawValueTransferCodingProvider),
            externalReference: dateTypeExternal(),
            expecteds: ["""
export type S = {
    rawValue: Date;
} & TagRecord<"S">;
""", """
export type S_JSON = string;
""", """
export function S_decode(json: S_JSON): S {
    return {
        rawValue: Date_decode(json)
    };
}
""", """
export function S_encode(entity: S): S_JSON {
    return Date_encode(entity.rawValue);
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
            typeConverterProvider: .init(typeMap: dateTypeMap(), customProvider: rawValueTransferCodingProvider),
            externalReference: dateTypeExternal(),
            expecteds: ["""
export type S = {
    rawValue: K<Date>;
} & TagRecord<"S">;
""", """
export type S_JSON = K_JSON<string>;
""", """
export function S_decode(json: S_JSON): S {
    return {
        rawValue: K_decode<Date, string>(json, Date_decode)
    };
}
""", """
export function S_encode(entity: S): S_JSON {
    return K_encode<Date, string>(entity.rawValue, Date_encode);
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
            typeConverterProvider: .init(customProvider: rawValueTransferCodingProvider),
            expecteds: ["""
export type S = {
    rawValue: K<E>;
} & TagRecord<"S">;
""", """
export type S_JSON = K_JSON<E_JSON>;
""", """
export function S_decode(json: S_JSON): S {
    return {
        rawValue: K_decode<E, E_JSON>(json, E_decode)
    };
}
""", """
export function S_encode(entity: S): S_JSON {
    return entity.rawValue as K_JSON<E_JSON>;
}
"""
                       ]
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
            typeConverterProvider: .init(customProvider: rawValueTransferCodingProvider),
            expecteds: ["""
export type S = {
    rawValue: K<number>;
} & TagRecord<"S">;
""", """
export type S_JSON = K<number>;
""", """
export function S_decode(json: S_JSON): S {
    return {
        rawValue: json as K<number>
    };
}
""", """
export function S_encode(entity: S): S_JSON {
    return entity.rawValue as K<number>;
}
"""
                       ]
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
            typeConverterProvider: .init(customProvider: rawValueTransferCodingProvider),
            expecteds: ["""
export type S<U> = {
    rawValue: K<U>;
} & TagRecord<"S", [U]>;
""", """
export type S_JSON<U_JSON> = K_JSON<U_JSON>;
""", """
export function S_decode<U, U_JSON>(json: S_JSON<U_JSON>, U_decode: (json: U_JSON) => U): S<U> {
    return {
        rawValue: K_decode<U, U_JSON>(json, U_decode)
    };
}
""", """
export function S_encode<U, U_JSON>(entity: S<U>, U_encode: (entity: U) => U_JSON): S_JSON<U_JSON> {
    return K_encode<U, U_JSON>(entity.rawValue, U_encode);
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
    a: S_JSON<number>;
}
""", """
export function K_decode(json: K_JSON): K {
    const a = S_decode<number, number>(json.a, identity);
    return {
        a: a
    };
}
""", """
export function K_encode(entity: K): K_JSON {
    const a = S_encode<number, number>(entity.a, identity);
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
}
