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
    return S_decode(json, T_decode);
}
""", """
export function A_encode<T, T_JSON>(entity: A<T>, T_encode: (entity: T) => T_JSON): A_JSON<T_JSON> {
    return S_encode(entity, T_encode);
}
"""
        ])

    }


}
