import XCTest
import CodableToTypeScript
import SwiftTypeReader

final class GenerateNestedTests: GenerateTestCaseBase {
    func testNestedTypeProperty() throws {
        let typeMap = TypeMap { (type) in
            let repr = type.toTypeRepr(containsModule: false)
            if let ident = repr.asIdent,
               ident.elements.last?.name == "ID"
            {
                return .identity(name: "string")
            }

            return nil
        }

        try assertGenerate(
            source: """
struct S {
    var a: A.ID
}
""",
            typeMap: typeMap,
            expecteds: ["""
export type S = {
    a: string;
} & TagRecord<"S">;
"""]
        )
    }

    func testNestedStructType() throws {
        try assertGenerate(
            source: """
struct A {
    struct B {
        var a: Int
    }
}
""",
            expecteds: ["""
export type A = {} & TagRecord<"A">;
""", """
export type A_B = {
    a: number;
} & TagRecord<"A_B">;
"""]
        )
    }

    func testDoubleNestedType() throws {
        try assertGenerate(
            source: """
struct A {
    struct B {
        struct C {
            var a: Int
        }
    }
}
""",
            expecteds: ["""
export type A
""", """
export type A_B
""", """
export type A_B_C
"""]
        )
    }

    func testNestedEnumType() throws {
        try assertGenerate(
            source: """
enum A {
    enum B {
        case c
    }
}
""",
            expecteds: ["""
export type A
""", """
export type A_B
""", """
export type A_B$JSON
""", """
export function A_B_decode(json: A_B$JSON): A_B
"""
            ]
        )
    }

    func testNestedTypeRef() throws {
        try assertGenerate(
            source: """
struct A {
    struct B {}
}

struct C {
    var b: A.B
}
""",
            typeSelector: .name("C"),
            expecteds: ["""
import { A_B, TagRecord } from "..";
""", """
export type C = {
    b: A_B;
} & TagRecord<"C">;
"""]
        )
    }

}
