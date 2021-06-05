import XCTest
@testable import CodableToTypeScript
import TestUtils
import TSCodeModule

final class EnumConvertTests: XCTestCase {

    static let jsonType = TSUnionType([
        .record([.init(name: "a", type: .record([]))]),
        .record([.init(name: "b", type: .record([
            .init(name: "_0", type: .named("number"))
        ]))])
    ])

    func testMakeTaggedType() throws {
        let t = EnumConverter.makeTaggedType(jsonType: Self.jsonType)
        XCTAssertEqual(t.description, """
{
  kind: "a";
  a: {
  };
} | {
  kind: "b";
  b: {
    _0: number;
  };
}
""")
    }

    func testMakeDecodeFunc() throws {
        let f = EnumConverter.makeDecodeFunc(
            taggedName: "E", jsonName: "EJSON", jsonType: Self.jsonType
        )
        print(f)
    }
}
