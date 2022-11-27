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
                return .init(name: "string")
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
};
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
export type A = {};
""", """
export type A_B = {
    a: number;
};
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
export type A_B_JSON
""", """
export function A_B_decode(json: A_B_JSON): A_B
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
import { A_B } from "..";
""", """
export type C = {
    b: A_B;
};
"""]
        )
    }

}
