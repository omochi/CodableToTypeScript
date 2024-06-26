import XCTest
import CodableToTypeScript
import SwiftTypeReader

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
export type S$JSON = string;
""", """
export function S_decode(json: S$JSON): S {
    return {
        rawValue: json
    };
}
""", """
export function S_encode(entity: S): S$JSON {
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
export type K$JSON = {
    a: S$JSON;
};
""", """
export function K_decode(json: K$JSON): K {
    const a = S_decode(json.a);
    return {
        a: a
    };
}
""", """
export function K_encode(entity: K): K$JSON {
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
export type S$JSON = string;
""", """
export function S_decode(json: S$JSON): S {
    return {
        rawValue: json
    };
}
""", """
export function S_encode(entity: S): S$JSON {
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
           let rawValueType = `struct`.rawValueType(requiresTransferringRawValueType: false) {
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
export type S$JSON = K$JSON | null;
""", """
export function S_decode(json: S$JSON): S {
    return {
        rawValue: Optional_decode<K, K$JSON>(json, K_decode) ?? undefined
    };
}
""", """
export function S_encode(entity: S): S$JSON {
    return OptionalField_encode<K, K$JSON>(entity.rawValue, K_encode) ?? null;
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
export type S$JSON = number | null;
""", """
export function S_decode(json: S$JSON): S {
    return {
        rawValue: json as number | null ?? undefined
    };
}
""", """
export function S_encode(entity: S): S$JSON {
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
export type S$JSON = K$JSON | null;
""", """
export function S_decode(json: S$JSON): S {
    return {
        rawValue: Optional_decode<K, K$JSON>(json, K_decode) ?? undefined
    };
}
""", """
export function S_encode(entity: S): S$JSON {
    return OptionalField_encode<K | null, K$JSON | null>(entity.rawValue, (entity: K | null): K$JSON | null => {
        return Optional_encode<K, K$JSON>(entity, K_encode);
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
export type S$JSON = string[];
""", """
export function S_decode(json: S$JSON): S {
    return {
        rawValue: json as string[]
    };
}
""", """
export function S_encode(entity: S): S$JSON {
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
export type S$JSON = K;
""", """
export function S_decode(json: S$JSON): S {
    return {
        rawValue: json
    };
}
""", """
export function S_encode(entity: S): S$JSON {
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
export type S$JSON = E$JSON;
""", """
export function S_decode(json: S$JSON): S {
    return {
        rawValue: E_decode(json)
    };
}
""", """
export function S_encode(entity: S): S$JSON {
    return entity.rawValue as E$JSON;
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
export type S$JSON = K$JSON;
""", """
export function S_decode(json: S$JSON): S {
    return {
        rawValue: K_decode(json)
    };
}
""", """
export function S_encode(entity: S): S$JSON {
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
export type S$JSON = string;
""", """
export function S_decode(json: S$JSON): S {
    return {
        rawValue: Date_decode(json)
    };
}
""", """
export function S_encode(entity: S): S$JSON {
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
export type S$JSON = K$JSON<string>;
""", """
export function S_decode(json: S$JSON): S {
    return {
        rawValue: K_decode<Date, string>(json, Date_decode)
    };
}
""", """
export function S_encode(entity: S): S$JSON {
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
export type S$JSON = K$JSON<E$JSON>;
""", """
export function S_decode(json: S$JSON): S {
    return {
        rawValue: K_decode<E, E$JSON>(json, E_decode)
    };
}
""", """
export function S_encode(entity: S): S$JSON {
    return entity.rawValue as K$JSON<E$JSON>;
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
export type S$JSON = K<number>;
""", """
export function S_decode(json: S$JSON): S {
    return {
        rawValue: json as K<number>
    };
}
""", """
export function S_encode(entity: S): S$JSON {
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
export type S$JSON<U$JSON> = K$JSON<U$JSON>;
""", """
export function S_decode<U, U$JSON>(json: S$JSON<U$JSON>, U_decode: (json: U$JSON) => U): S<U> {
    return {
        rawValue: K_decode<U, U$JSON>(json, U_decode)
    };
}
""", """
export function S_encode<U, U$JSON>(entity: S<U>, U_encode: (entity: U) => U$JSON): S$JSON<U$JSON> {
    return K_encode<U, U$JSON>(entity.rawValue, U_encode);
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
export type S$JSON<T$JSON> = {
    rawValue: T$JSON;
};
""", """
export function S_decode<T, T$JSON>(json: S$JSON<T$JSON>, T_decode: (json: T$JSON) => T): S<T> {
    const rawValue = T_decode(json.rawValue);
    return {
        rawValue: rawValue
    };
}
""", """
export function S_encode<T, T$JSON>(entity: S<T>, T_encode: (entity: T) => T$JSON): S$JSON<T$JSON> {
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
""",
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
export type User_ID$JSON = string;
""", """
export function User_ID_decode(json: User_ID$JSON): User_ID {
    return {
        rawValue: json
    };
}
""", """
export function User_ID_encode(entity: User_ID): User_ID$JSON {
    return entity.rawValue;
}
""", """
export type User = {
    id: User_ID;
    date: Date;
} & TagRecord<"User">;
""", """
export type User$JSON = {
    id: User_ID$JSON;
    date: string;
};
""", """
export function User_decode(json: User$JSON): User {
    const id = User_ID_decode(json.id);
    const date = Date_decode(json.date);
    return {
        id: id,
        date: date
    };
}
""", """
export function User_encode(entity: User): User$JSON {
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
export type ID$JSON<G$JSON> = string;
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
export type S$JSON = number;
""", """
export function S_decode(json: S$JSON): S {
    return {
        rawValue: json
    };
}
""", """
export function S_encode(entity: S): S$JSON {
    return entity.rawValue;
}
"""
                       ]
        )
    }

    func testRawValueType() throws {
        let source = """
struct A: RawRepresentable {
    var rawValue: Int
}

struct B<T>: RawRepresentable {
    var rawValue: T
}

struct C: RawRepresentable {
    var rawValue: Int?
}

struct K {
    var a: A
    var b: B<Int>
    var c: C
}
"""
        let context = Context()
        let reader = Reader(context: context)
        let module = reader.read(source: source, file: URL(fileURLWithPath: "main.swift")).module

        let k = try XCTUnwrap(module.find(name: "K")?.asStruct)
        let aType = try XCTUnwrap(k.find(name: "a")?.asVar?.interfaceType.asStruct)
        XCTAssertEqual(aType.rawValueType(requiresTransferringRawValueType: false)?.description, "Int")
        XCTAssertEqual(aType.rawValueType(requiresTransferringRawValueType: true)?.description, "Int")

        let bType = try XCTUnwrap(k.find(name: "b")?.asVar?.interfaceType.asStruct)
        XCTAssertEqual(bType.rawValueType(requiresTransferringRawValueType: false)?.description, "Int")
        XCTAssertEqual(bType.rawValueType(requiresTransferringRawValueType: true)?.description, nil)

        let cType = try XCTUnwrap(k.find(name: "c")?.asVar?.interfaceType.asStruct)
        XCTAssertEqual(cType.rawValueType(requiresTransferringRawValueType: false)?.description, "Optional<Int>")
        XCTAssertEqual(cType.rawValueType(requiresTransferringRawValueType: true)?.description, nil)
    }
}
