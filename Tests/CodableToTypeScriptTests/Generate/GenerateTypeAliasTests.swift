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
export type A_JSON
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
export type A_JSON = S_JSON;
""", """
export function A_decode(json: A_JSON): A {
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
export type A_JSON<T_JSON> = S_JSON<T_JSON>;
""", """
export function A_decode<T, T_JSON>(json: A_JSON<T_JSON>, T_decode: (json: T_JSON) => T): A<T> {
    return S_decode<T, T_JSON>(json, T_decode);
}
""", """
export function A_encode<T, T_JSON>(entity: A<T>, T_encode: (entity: T) => T_JSON): A_JSON<T_JSON> {
    return S_encode<T, T_JSON>(entity, T_encode);
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
export type A_JSON<T_JSON> = S_JSON;
""", """
export function A_decode<T, T_JSON>(json: A_JSON<T_JSON>, T_decode: (json: T_JSON) => T): A<T> {
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
export type S_A_JSON<T_JSON> = E_JSON<T_JSON>;
""", """
export function S_A_decode<T, T_JSON>(json: S_A_JSON<T_JSON>, T_decode: (json: T_JSON) => T): S_A<T> {
    return E_decode<T, T_JSON>(json, T_decode);
}
""", """
export function S_A_encode<T, T_JSON>(entity: S_A<T>, T_encode: (entity: T) => T_JSON): S_A_JSON<T_JSON> {
    return E_encode<T, T_JSON>(entity, T_encode);
}
"""
            ]
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
export type User_JSON = {
    id: User_ID_JSON;
};
""", """
export type User_ID = GenericID<User>;
""", """
export type User_ID_JSON = string;
""", """
export function User_ID_decode(json: User_ID_JSON): User_ID {
    return GenericID_decode<User, User_JSON>(json, User_decode);
}
"""
            ]
        )
    }
}
