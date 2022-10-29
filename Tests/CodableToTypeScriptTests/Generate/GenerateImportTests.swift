import XCTest
@testable import CodableToTypeScript
import SwiftTypeReader
import TSCodeModule

final class GenerateImportTests: GenerateTestCaseBase {
    func testGenericStruct() throws {
        try assertGenerate(
            source: """
struct S<T, U> {
    var a: A?
    var b: number
    var c: [B]
    var t: T
    var xc: X<C>
    var xu: X<U>
    var yc: Y<C>
    var yu: Y<U>
}

struct X<T> {}
""",
            typeSelector: .name("S"),
            expecteds: ["""
import {
    A,
    B,
    C,
    X,
    Y
} from "..";
"""
            ]
        )
    }

    func testDefaultStandardTypes() throws {
        try assertGenerate(
            source: """
struct S {
    var a: Int
    var b: Bool
    var c: String
    var d: Double?
}
""",
            unexpecteds: ["import"]
        )
    }
}
