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

    private func assertGenerate(
        source: String, expected: String,
        file: StaticString = #file, line: UInt = #line
    ) throws {
        let tsCode = try Utils.generate(
            source: source,
            type: { (_) in true },
            file: file, line: line
        )
        XCTAssertEqual(tsCode.description, expected)
    }
}
