import XCTest
import CodableToTypeScript

final class GenerateTypeAliasTests: GenerateTestCaseBase {
    func testTrivial() throws {
        try assertGenerate(
            source: """
typealias A = Int
""",
            expecteds: ["""
export type A = number;
"""
            ],
            unexpecteds: ["""
export type A$JSON
"""]
        )
    }

    func testDecode() throws {
        try assertGenerate(
            source: """
enum E { case a }
struct S { var e: E }

typealias A = S
""",
            expecteds: ["""
export type A = S;
""", """
export type A$JSON = S$JSON;
""", """
export function A_decode(json: A$JSON): A {
    return S_decode(json);
}
"""]
        )
    }

    func testGenericParamTransfer() throws {
        try assertGenerate(
            source: """
struct S<T> { var a: T }

typealias A<T> = S<T>
""",
        expecteds: ["""
export type A<T> = S<T>;
""", """
export type A$JSON<T$JSON> = S$JSON<T$JSON>;
""", """
export function A_decode<T, T$JSON>(json: A$JSON<T$JSON>, T_decode: (json: T$JSON) => T): A<T> {
    return S_decode<T, T$JSON>(json, T_decode);
}
""", """
export function A_encode<T, T$JSON>(entity: A<T>, T_encode: (entity: T) => T$JSON): A$JSON<T$JSON> {
    return S_encode<T, T$JSON>(entity, T_encode);
}
"""
        ])
    }

    func testGenericParamDrop() throws {
        try assertGenerate(
            source: """
enum E { case a }
struct S { var e: E }

typealias A<T> = S
""",
        expecteds: ["""
export type A<T> = S;
""", """
export type A$JSON<T$JSON> = S$JSON;
""", """
export function A_decode<T, T$JSON>(json: A$JSON<T$JSON>, T_decode: (json: T$JSON) => T): A<T> {
    return S_decode(json);
}
"""
        ])
    }

    func testNested() throws {
        try assertGenerate(
            source: """
enum E<X> { case a(X) }

struct S {
    typealias A<T> = E<T>
}
""",
            typeSelector: .name("A", recursive: true),
            expecteds: ["""
export type S_A<T> = E<T>;
""", """
export type S_A$JSON<T$JSON> = E$JSON<T$JSON>;
""", """
export function S_A_decode<T, T$JSON>(json: S_A$JSON<T$JSON>, T_decode: (json: T$JSON) => T): S_A<T> {
    return E_decode<T, T$JSON>(json, T_decode);
}
""", """
export function S_A_encode<T, T$JSON>(entity: S_A<T>, T_encode: (entity: T) => T$JSON): S_A$JSON<T$JSON> {
    return E_encode<T, T$JSON>(entity, T_encode);
}
"""
            ]
        )
    }

    func testInheritGenericParam() throws {
        let source = """
struct E<X> {}

struct S<T> {
    typealias A = E<T>
    typealias B = E<Int>
}
"""

        try assertGenerate(
            source: source,
            typeSelector: .name("A", recursive: true),
            expecteds: ["""
export type S_A<T> = E<T>;
"""]
        )

        try assertGenerate(
            source: source,
            typeSelector: .name("B", recursive: true),
            expecteds: ["""
export type S_B<T> = E<number>;
"""]
        )
    }

    func testRawRepr() throws {
        try assertGenerate(
            source: """
struct GenericID<T>: RawRepresentable {
    var rawValue: String
}

struct User {
    typealias ID = GenericID<User>

    var id: ID
}
""",
            expecteds: ["""
export type User = {
    id: User_ID;
} & TagRecord<"User">;
""", """
export type User$JSON = {
    id: User_ID$JSON;
};
""", """
export type User_ID = GenericID<User>;
""", """
export type User_ID$JSON = GenericID$JSON<User$JSON>;
""", """
export function User_ID_decode(json: User_ID$JSON): User_ID {
    return GenericID_decode<User, User$JSON>(json, User_decode);
}
"""
            ]
        )
    }
}
