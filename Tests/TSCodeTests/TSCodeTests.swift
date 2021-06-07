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

        let code = TSCode(
            decls: [
                .typeDecl(name: "S1", type: s1)
            ]
        )

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
    a: {
    };
} | {
    kind: "b";
    b: {
    };
}
"""

        XCTAssertEqual(e.description, expected)
    }
}
