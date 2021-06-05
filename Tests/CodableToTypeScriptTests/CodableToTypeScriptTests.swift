import XCTest
@testable import CodableToTypeScript
import SwiftTypeReader

final class CodableToTypeScriptTests: XCTestCase {
    func testEnum() throws {
        let source = """
enum E {
    case a(x: Int, y: Int)
    case b([String])
"""
        let expected = """
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
"""

        let module = try Reader().read(source: source)
        let swType = try XCTUnwrap(module.types.compactMap { $0.enum }.first)
        let tsCode = CodeGenerator(typeMap: .default).generate(type: .enum(swType))
        XCTAssertEqual(tsCode.description, expected)
    }
}
