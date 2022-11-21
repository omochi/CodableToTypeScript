import XCTest
import CodableToTypeScript
import SwiftTypeReader

final class HelperLibraryTests: XCTestCase {
    func testHelperLibrary() {
        let gen = CodeGenerator(context: Context())
        let code = gen.generateHelperLibrary()

        let actual = code.description
//        print(actual)

        XCTAssertTrue(actual.contains("""
export function identity<T>(json: T): T
"""))

        XCTAssertTrue(actual.contains("""
export function OptionalField_decode<T, U>(json: T | undefined, T_decode: (json: T) => U): U | undefined
"""))

        XCTAssertTrue(actual.contains("""
export function Optional_decode<T, U>(json: T | null, T_decode: (json: T) => U): U | null
"""))

        XCTAssertTrue(actual.contains("""
export function Array_decode<T, U>(json: T[], T_decode: (json: T) => U): U[]
"""))

        XCTAssertTrue(actual.contains("""
export function Dictionary_decode<T, U>(json: { [key: string]: T; }, T_decode: (json: T) => U): { [key: string]: U; }
"""))
    }
}
