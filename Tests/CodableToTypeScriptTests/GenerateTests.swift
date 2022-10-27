import XCTest
@testable import CodableToTypeScript
import SwiftTypeReader

final class GenerateTests: XCTestCase {
    // MARK: DEBUG
    var prints: Bool = true

    func testGenericStruct() throws {
        try assertGenerate(
            source: """
struct S<T> {
    var a: T
}
""",
            typeSelector: .name("S"),
            expecteds: ["""
export type S<T> = {
    a: T;
};
"""]
        )
    }

    func testChildEnum() throws {
        try assertGenerate(
            source: """
enum E {
    case a
}

struct S {
    var a: E
}
""",
            typeSelector: .name("S"),
            expecteds: ["""
export type S = {
    a: EJSON;
};
"""]
        )
    }

    func testGenericArguments() throws {
        try assertGenerate(
            source: """
struct S1<T> {
    var a: S2<T>
}
""",
            typeSelector: .name("S1"),
            expecteds: ["""
export type S1<T> = {
    a: S2<T>;
};
"""]
        )
    }

    func testGenericEnum() throws {
        try assertGenerate(
            source: """
enum E<T> {
    case a(T)
}
""",
            typeSelector: .name("E"),
            expecteds: [
                """
export type EJSON<T> = {
    a: {
        _0: T;
    };
};
""",
                """
export type E<T> = {
    kind: "a";
    a: {
        _0: T;
    };
};
""",
                """
export function EDecode<T>(json: EJSON<T>): E<T>
"""

            ]
        )
    }

    func testStringRawValueEnum() throws {
        try assertGenerate(
            source: """
enum E: String, Codable {
    case aaa
    case iii
}
""",
            typeSelector: .name("E"),
            expecteds: [
                """
export type E = "aaa" |
"iii";
""",
            ]
        )
    }

    func testNestedTypeProperty() throws {
        let typeMap = TypeMap { (specifier) in
            if specifier.lastElement.name == "ID" {
                return "string"
            }

            return nil
        }

        try assertGenerate(
            source: """
struct S {
    var a: A.ID
}
""",
            typeSelector: .name("S"),
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
            typeSelector: .name("A"),
            expecteds: ["""
export type A = {
};
""", """
export namespace A {
    export type B = {
        a: number;
    };
}
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
            typeSelector: .name("A"),
            expecteds: ["""
export namespace A {
""", """
    export namespace B {
""", """
        export type C
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
            typeSelector: .name("A"),
            expecteds: ["""
export namespace A {
""", """
    export type BJSON
""", """
    export type B
""", """
    export function BDecode(json: BJSON): B
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
import {
    A
} from "..";
""", """
export type C = {
    b: A.B;
};
"""]
        )
    }

    func testTranspileUnresolvedRef() throws {
        try assertGenerate(
            source: """
struct Q {
    var id: ID
    var ids: [ID]
}
""",
            typeSelector: .name("Q"),
            expecteds: ["""
export type Q = {
    id: ID;
    ids: ID[];
};
"""]
        )
    }

    private func assertGenerate(
        source: String,
        typeSelector: TypeSelector,
        typeMap: TypeMap? = nil,
        expecteds: [String],
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let tsCode = try Utils.generate(
            source: source,
            typeMap: typeMap,
            typeSelector: typeSelector,
            file: file, line: line
        )
        let actual = tsCode.description
        if prints {
            print(actual)
        }
        for expected in expecteds {
            if !actual.contains(expected) {
                XCTFail("\(actual) does not contain \(expected)")
            }
        }
    }
}
