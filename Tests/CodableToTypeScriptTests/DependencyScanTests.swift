import XCTest
import CodableToTypeScript
import TSCodeModule

final class DependencyScanTests: XCTestCase {
    func testStruct() throws {
        let code = TSCode([
            .decl(.type(
                name: "X", genericParameters: [.init("T")],
                type: .record([])
            )),
            .decl(.type(
                name: "S", genericParameters: [.init("T"), .init("U")],
                type: .record([
                    .init(name: "a", type: .named("A"), isOptional: true),
                    .init(name: "b", type: .named("number")),
                    .init(name: "c", type: .array(.named("C"))),
                    .init(name: "d", type: .named("T")),
                    .init(name: "e", type: .named("X", genericArguments: [.init(.named("E"))])),
                    .init(name: "f", type: .named("X", genericArguments: [.init(.named("U"))])),
                    .init(name: "g", type: .named("Y", genericArguments: [.init(.named("G"))])),
                    .init(name: "h", type: .named("Y", genericArguments: [.init(.named("U"))])),
                ])
            ))
        ])

        XCTAssertEqual(code.description, """
export type X<T> = {};

export type S<T, U> = {
    a?: A;
    b: number;
    c: C[];
    d: T;
    e: X<E>;
    f: X<U>;
    g: Y<G>;
    h: Y<U>;
};

""")

        let d = DependencyScanner().scan(code: code)
        XCTAssertEqual(d, ["A", "C", "E", "G", "Y"])
    }

    func testInterface() throws {
        let code = TSCode([
            .decl(.interface(TSInterfaceDecl(
                name: "I", genericParameters: [.init("T")], extends: [.named("J")],
                decls: [
                    .method(TSMethodDecl(
                        name: "foo", genericParameters: [.init("U")],
                        parameters: [
                            .init(name: "a", type: .named("A")),
                            .init(name: "t", type: .named("T")),
                            .init(name: "u", type: .named("U"))
                        ],
                        returnType: .named("B")
                    ))
                ]
            )))
        ])

        XCTAssertEqual(code.description, """
export interface I<T> extends J {
    foo<U>(a: A, t: T, u: U): B;
}

""")

        let d = DependencyScanner().scan(code: code)
        XCTAssertEqual(d, ["A", "B", "J"])
    }

    func testClass() throws {
        let code = TSCode([
            .decl(.class(TSClassDecl(
                name: "C", genericParameters: [.init("T")],
                extends: .named("D"), implements: [.named("I")],
                items: [
                    .decl(.method(TSMethodDecl(
                        name: "foo", genericParameters: [.init("U")],
                        parameters: [
                            .init(name: "a", type: .named("A")),
                            .init(name: "t", type: .named("T")),
                            .init(name: "u", type: .named("U"))
                        ],
                        returnType: .named("B"),
                        items: [
                            .stmt(.return(
                                .infixOperator(
                                    .infixOperator(
                                        .identifier("a"),
                                        "+",
                                        .identifier("b")
                                    ),
                                    "+",
                                    .identifier("t")
                                )
                            ))
                        ]
                    )))

                ]
            )))
        ])

        XCTAssertEqual(code.description, """
export class C<T> extends D implements I {
    foo<U>(a: A, t: T, u: U): B {
        return a + b + t;
    }
}

""")

        let d = DependencyScanner().scan(code: code)
        XCTAssertEqual(d, ["A", "B", "D", "I", "b"])
    }
}
