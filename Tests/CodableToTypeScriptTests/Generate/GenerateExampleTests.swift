import XCTest
import TestUtils
import CodableToTypeScript
import SwiftTypeReader

final class GenerateExampleTests: GenerateTestCaseBase {
    func testStruct() throws {
        try assertGenerate(
            source: """
struct S {
    var x: Int
    var o1: Int?
    var o2: Int??
    var o3: Int???
    var a1: [Int?]
    var d1: [String: Int]
}
""",
            expecteds: ["""
export type S = {
    x: number;
    o1?: number;
    o2?: number | null;
    o3?: number | null;
    a1: (number | null)[];
    d1: { [key: string]: number; };
};

"""]
        )
    }

    func testEnum() throws {
        try assertGenerate(
            source: """
enum E {
    case a(x: Int, y: Int)
    case b([String])
""",
            expecteds: ["""
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
""", """
export type E_JSON = {
    a: {
        x: number;
        y: number;
    };
} | {
    b: {
        _0: string[];
    };
};
""", """
export function E_decode(json: E_JSON): E {
    if ("a" in json) {
        const j = json.a;
        return {
            kind: "a",
            a: {
                x: j.x,
                y: j.y
            }
        };
    } else if ("b" in json) {
        const j = json.b;
        return {
            kind: "b",
            b: {
                _0: j._0
            }
        };
    } else {
        throw new Error("unknown kind");
    }
}
"""])
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
            expecteds: ["""
import {
    E1,
    E1_JSON,
    E2,
    E2_JSON
} from "..";
""", """
export type S = {
    x: E1;
    y: E2;
};
""", """
export type S_JSON = {
    x: E1_JSON;
    y: E2_JSON;
};
""", """
export function S_decode(json: S_JSON): S {
    return {
        x: E1_decode(json.x),
        y: json.y
    };
}
"""]
        )
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
}
