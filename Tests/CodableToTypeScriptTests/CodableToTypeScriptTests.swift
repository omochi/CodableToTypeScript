import XCTest
@testable import CodableToTypeScript
import SwiftTypeReader

final class CodableToTypeScriptTests: XCTestCase {
    func testStruct() throws {
        try assertGenerate(source: """
struct S {
    var x: Int
    var o1: Int?
    var o2: Int??
    var o3: Int???
    var a1: [Int?]
    var d1: [String: Int]
}
""", expected: """
export type S = {
    x: number;
    o1?: number;
    o2?: number | null;
    o3?: number | null;
    a1: (number | null)[];
    d1: { [key: string]: number; };
};

""")
    }

    func testEnum() throws {
        try assertGenerate(source: """
enum E {
    case a(x: Int, y: Int)
    case b([String])
""", expected: """
export type EJSON = {
    a: {
        x: number;
        y: number;
    };
} | {
    b: {
        _0: string[];
    };
};

export type E = {
    kind: "a";
    a: {
        x: number;
        y: number;
    };
} | {
    kind: "b";
    b: {
        _0: string[];
    };
};

export function EDecode(json: EJSON): E {
    if ("a" in json) {
        return { "kind": "a", a: json.a };
    } else if ("b" in json) {
        return { "kind": "b", b: json.b };
    } else {
        throw new Error("unknown kind");
    }
}

""")
    }

    func testEnumInStruct() throws {
        try assertGenerate(
            source: """
enum E1 {
    case a
}

enum E2: String {
    case a
}

struct S {
    var x: E1
    var y: E2
}
""",
            typeSelector: .name("S"),
            expected: """
import {
    E1JSON,
    E2
} from "..";

export type S = {
    x: E1JSON;
    y: E2;
};

""")
    }

    func testTranspileTypeReference() throws {
        let modules = Modules()
        let module = try SwiftTypeReader.Reader(modules: modules).read(source: """
struct S {
    var ids: [ID]
}
"""
        ).module

        let s = try XCTUnwrap(module.getType(name: "S"))
        let idsSwift = try XCTUnwrap(s.struct?.storedProperties[safe: 0]?.type())

        XCTAssertEqual(idsSwift.description, "Swift.Array<ID>")

        let gen = CodeGenerator(typeMap: .default)
        let idsTS = try gen.transpileTypeReference(type: idsSwift)

        XCTAssertEqual(idsTS.description, "ID[]")
    }

    private func assertGenerate(
        source: String,
        typeSelector: TypeSelector? = nil,
        expected: String,
        file: StaticString = #file, line: UInt = #line
    ) throws {
        let tsCode = try Utils.generate(
            source: source,
            typeSelector: typeSelector ?? .first(file: file, line: line),
            file: file, line: line
        )
        XCTAssertEqual(tsCode.description, expected)
    }
}
