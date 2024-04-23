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
        XCTAssertEqual(try sConverter.decodePresence(), .required)
        XCTAssertEqual(try sConverter.encodePresence(), .required)

        let aDecl = try XCTUnwrap(source.find(name: "A"))

        let fooType = try XCTUnwrap(aDecl.asStruct?
            .findInNominalTypeDecl(name: "foo", options: LookupOptions())?
            .asVar?
            .interfaceType)
        let fooConverter = try CodeGenerator(context: context)
            .converter(for: fooType)
        XCTAssertEqual(try fooConverter.decodePresence(), .identity)
        XCTAssertEqual(try fooConverter.encodePresence(), .identity)

        let barType = try XCTUnwrap(aDecl.asStruct?
            .findInNominalTypeDecl(name: "bar", options: LookupOptions())?
            .asVar?
            .interfaceType)
        let barConverter = try CodeGenerator(context: context)
            .converter(for: barType)
        XCTAssertEqual(try barConverter.decodePresence(), .required)
        XCTAssertEqual(try barConverter.encodePresence(), .required)

        let bazType = try XCTUnwrap(aDecl.asStruct?
            .findInNominalTypeDecl(name: "baz", options: LookupOptions())?
            .asVar?
            .interfaceType)
        let bazConverter = try CodeGenerator(context: context)
            .converter(for: bazType)
        XCTAssertThrowsError(try bazConverter.decodePresence()) { (error) in
            XCTAssertTrue("\(error)".contains("Error type can't be evaluated: UNKNOWN"))
        }
        XCTAssertThrowsError(try bazConverter.encodePresence()) { (error) in
            XCTAssertTrue("\(error)".contains("Error type can't be evaluated: UNKNOWN"))
        }
    }
}
