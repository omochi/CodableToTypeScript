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
            .decl(.type(name: "S1", type: s1))
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
"a" | "b" | "c"
"""
        XCTAssertEqual(e.description, expected)
    }

    func testImport() {
        let imp = TSImportDecl(names: ["A", "B", "C"], from: "..")

        let expected = """
import { A, B, C } from "..";

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
                .type(name: "B", type: b)
            ]
        )

        let code = TSCode([
            .decl(.namespace(ns))
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

    func testInterface() {
        let t = TSInterfaceDecl(
            name: "I",
            genericParameters: [.init("T")],
            extends: [.named("J")],
            decls: [
                .method(TSMethodDecl(
                    name: "a",
                    genericParameters: [.init("U")],
                    parameters: [.init(name: "x", type: .named("T"))],
                    returnType: .named("U")
                ))
            ]
        )

        XCTAssertEqual(t.description, """
export interface I<T> extends J {
    a<U>(x: T): U;
}

""")
    }

    func testClass1() {

        let d = TSClassDecl(name: "A", items: [])
        XCTAssertEqual(d.description, """
export class A {
}

""")

    }

    func testClass2() {
        let d = TSClassDecl(
            name: "A",
            genericParameters: [.init("T")],
            extends: .named("B", genericArguments: [.init(.named("T"))]),
            implements: [.named("I", genericArguments: [.init(.named("T"))])],
            items: [
                .decl(.method(TSMethodDecl(
                    name: "a", parameters: [], returnType: .named("number"),
                    items: [
                        .stmt(.return(.numberLiteral("1.0")))
                    ]
                )))
            ]
        )
        XCTAssertEqual(d.description, """
export class A<T> extends B<T> implements I<T> {
    a(): number {
        return 1.0;
    }
}

""")
    }

    func testClass3() {
        let d = TSClassDecl(
            name: "A",
            extends: .named("B"),
            implements: [.named("I"), .named("J"), .named("K"), .named("L")],
            items: [
                .decl(.method(TSMethodDecl(
                    modifiers: ["async"], name: "a", parameters: [],
                    returnType: .named("Promise", genericArguments: [.init(.named("number"))]),
                    items: [ .stmt(.return(.numberLiteral("1")))]
                ))),
                .decl(.method(TSMethodDecl(
                    modifiers: ["async"], name: "b", parameters: [],
                    returnType: .named("Promise", genericArguments: [.init(.named("number"))]),
                    items: [
                        .stmt(.return(
                            .prefixOperator(
                                "await",
                                .call(
                                    callee: .memberAccess(base: .identifier("this"), name: "a"),
                                    arguments: []
                                )
                            )
                        ))
                    ]
                )))
            ]
        )

        XCTAssertEqual(d.description, """
export class A extends B implements
    I,
    J,
    K,
    L
{
    async a(): Promise<number> {
        return 1;
    }

    async b(): Promise<number> {
        return await this.a();
    }
}

""")
    }
}
