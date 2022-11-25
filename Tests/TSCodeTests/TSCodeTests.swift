import XCTest
import TypeScriptAST

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

    func testImports() {
        let e: TSCode = .init([
            .decl(.import(names: ["A", "B"], from: "./ab.js")),
            .decl(.import(names: ["C"], from: "./c.js")),
            .decl(.import(names: ["D", "E", "F", "G", "H", "I"], from: "./defghi.js")),
            .decl(.function(.init(name: "foo", parameters: [], returnType: nil, items: [])))
        ])
        let expected = """
import { A, B } from "./ab.js";
import { C } from "./c.js";
import {
    D,
    E,
    F,
    G,
    H,
    I
} from "./defghi.js";

export function foo() {
}

"""

        XCTAssertEqual(e.description, expected)
    }

    func testNewLineBetweenDecls() {
        let e: TSCode = .init([
            .decl(.import(names: ["A", "B"], from: "./ab.js")),
            .decl(.import(names: ["C"], from: "./c.js")),
            .decl(.interface(.init(name: "I", decls: [
                .field(.init(name: "value1", type: .named("A"))),
                .field(.init(name: "value2", type: .named("B"))),
                .method(.init(name: "f1", parameters: [], returnType: nil)),
                .method(.init(name: "f2", parameters: [], returnType: nil)),
            ]))),
            .decl(.function(.init(name: "foo", parameters: [], returnType: nil, items: [
                .decl(.var(kind: "const", name: "c1", type: .orUndefined(.named("C")), initializer: .identifier("undefined"))),
                .decl(.var(kind: "const", name: "c2", type: .orUndefined(.named("C")), initializer: .identifier("undefined"))),
            ]))),
            .decl(.var(export: true, kind: "const", name: "c1", type: .orUndefined(.named("C")), initializer: .identifier("undefined"))),
            .decl(.var(export: true, kind: "const", name: "c2", type: .orUndefined(.named("C")), initializer: .identifier("undefined"))),
            .decl(.class(.init(name: "Bar", items: [
                .decl(.field(.init(name: "value1", type: .named("A")))),
                .decl(.field(.init(name: "value2", type: .named("B")))),
                .decl(.function(.init(export: false, name: "f1", parameters: [], returnType: .named("string"), items: [
                    .decl(.var(kind: "const", name: "c1", type: .orUndefined(.named("C")), initializer: .identifier("undefined"))),
                    .decl(.var(kind: "const", name: "c2", type: .orUndefined(.named("C")), initializer: .identifier("undefined"))),
                ]))),
                .decl(.function(.init(export: false, name: "f2", parameters: [], returnType: .named("string"), items: [
                ]))),
            ])))
        ])
        let expected = """
import { A, B } from "./ab.js";
import { C } from "./c.js";

export interface I {
    value1: A;
    value2: B;

    f1();
    f2();
}

export function foo() {
    const c1: C | undefined = undefined;
    const c2: C | undefined = undefined;
}

export const c1: C | undefined = undefined;

export const c2: C | undefined = undefined;

export class Bar {
    value1: A;
    value2: B;

    function f1(): string {
        const c1: C | undefined = undefined;
        const c2: C | undefined = undefined;
    }

    function f2(): string {
    }
}

"""

        XCTAssertEqual(e.description, expected)
    }
}
