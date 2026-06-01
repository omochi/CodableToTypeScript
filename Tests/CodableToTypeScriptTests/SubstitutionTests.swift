import CodableToTypeScript
@testable import SwiftTypeReader
import XCTest

final class SubstitutionTests: XCTestCase {
    func testStruct() throws {
        let context = Context()
        let source = Reader(context: context).read(source: """
struct S<T> {
    var value: T
}
struct A {
    var foo: S<String>
    var bar: S<[String: String]>
    var baz: S<UNKNOWN>
}
""", file: URL(fileURLWithPath: "main.swift"))

        let sType = try XCTUnwrap(source.find(name: "S")?.asStruct?.typedDeclaredInterfaceType)
        let sConverter = try CodeGenerator(context: context)
            .converter(for: sType)
        XCTAssertEqual(try sConverter.hasDecode(), true)
        XCTAssertEqual(try sConverter.hasEncode(), true)
        XCTAssertEqual(try sConverter.usesIdentityDecode(), false)
        XCTAssertEqual(try sConverter.usesIdentityEncode(), false)

        let aDecl = try XCTUnwrap(source.find(name: "A"))

        let fooType = try XCTUnwrap(aDecl.asStruct?
            .findInNominalTypeDecl(name: "foo", options: LookupOptions())?
            .asVar?
            .interfaceType)
        let fooConverter = try CodeGenerator(context: context)
            .converter(for: fooType)
        XCTAssertEqual(try fooConverter.hasDecode(), true)
        XCTAssertEqual(try fooConverter.hasEncode(), true)
        XCTAssertEqual(try fooConverter.usesIdentityDecode(), true)
        XCTAssertEqual(try fooConverter.usesIdentityEncode(), true)

        let barType = try XCTUnwrap(aDecl.asStruct?
            .findInNominalTypeDecl(name: "bar", options: LookupOptions())?
            .asVar?
            .interfaceType)
        let barConverter = try CodeGenerator(context: context)
            .converter(for: barType)
        XCTAssertEqual(try barConverter.hasDecode(), true)
        XCTAssertEqual(try barConverter.hasEncode(), true)
        XCTAssertEqual(try barConverter.usesIdentityDecode(), false)
        XCTAssertEqual(try barConverter.usesIdentityEncode(), false)

        let bazType = try XCTUnwrap(aDecl.asStruct?
            .findInNominalTypeDecl(name: "baz", options: LookupOptions())?
            .asVar?
            .interfaceType)
        let bazConverter = try CodeGenerator(context: context)
            .converter(for: bazType)
        XCTAssertEqual(try bazConverter.hasDecode(), true)
        XCTAssertEqual(try bazConverter.hasEncode(), true)
        XCTAssertThrowsError(try bazConverter.usesIdentityDecode()) { (error) in
            XCTAssertTrue("\(error)".contains("Error type can't be evaluated: UNKNOWN"), "rawError: \(error)")
        }
        XCTAssertThrowsError(try bazConverter.usesIdentityEncode()) { (error) in
            XCTAssertTrue("\(error)".contains("Error type can't be evaluated: UNKNOWN"), "rawError: \(error)")
        }
    }
}
