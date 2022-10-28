import XCTest
@testable import TSCodeModule

final class TSCodeTests: XCTestCase {
    func testBasic() {
        let s2: TSType = .record([
            .init(name: "a", type: .named("number")),
            .init(name: "b", type: .named("string"))
        ])

        let s1: TSType = .record([
            .init(name: "a", type: s2, isOptional: true)
        ])

        let code = TSCode([
            .decl(.typeDecl(name: "S1", type: s1))
        ])

        let expected = """
export type S1 = {
    a?: {
        a: number;
        b: string;
    };
};

"""

        XCTAssertEqual(code.description, expected)
    }

    func testUnion() {
        let e: TSType = .union([
            .record([
                .init(name: "kind", type: .stringLiteral("a")),
                .init(name: "a", type: .record([]))
            ]),
            .record([
                .init(name: "kind", type: .stringLiteral("b")),
                .init(name: "b", type: .record([]))
            ])
        ])

        let expected = """
{
    kind: "a";
    a: {};
} | {
    kind: "b";
    b: {};
}
"""

        XCTAssertEqual(e.description, expected)
    }

    func testLinedUnion() {
        let e: TSType = .union([
            .stringLiteral("a"),
            .stringLiteral("b"),
            .stringLiteral("c")
        ])

        let expected = """
"a" |
"b" |
"c"
"""
        XCTAssertEqual(e.description, expected)
    }

    func testImport() {
        let imp = TSImportDecl(names: ["A", "B", "C"], from: "..")

        let expected = """
import {
    A,
    B,
    C
} from "..";

"""
        XCTAssertEqual(imp.description, expected)
    }

    func testNamespace() {
        let b: TSType = .record([
            .init(name: "x", type: .named("string"))
        ])

        let ns = TSNamespaceDecl(
            name: "A",
            decls: [
                .typeDecl(name: "B", type: b)
            ]
        )

        let code = TSCode([
            .decl(.namespaceDecl(ns))
        ])

        let expected = """
export namespace A {
    export type B = {
        x: string;
    };
}

"""

        XCTAssertEqual(code.description, expected)
    }

    func testNestedType() {
        let t: TSNestedType = .init(
            namespace: "A",
            type: .named("B")
        )

        XCTAssertEqual(t.description, "A.B")
    }
}
