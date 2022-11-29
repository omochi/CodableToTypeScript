import XCTest
import CodableToTypeScript
import SwiftTypeReader

final class HelperLibraryTests: XCTestCase {
    func testHelperLibrary() {
        let gen = CodeGenerator(context: Context())
        let code = gen.generateHelperLibrary()

        let actual = code.print()

//        print(actual)

        XCTAssertTrue(actual.contains("""
export function identity<T>(json: T): T
"""))

        XCTAssertTrue(actual.contains("""
export function OptionalField_decode<T, T_JSON>(json: T_JSON | undefined, T_decode: (json: T_JSON) => T): T | undefined
"""))

        XCTAssertTrue(actual.contains("""
export function OptionalField_encode<T, T_JSON>(entity: T | undefined, T_encode: (entity: T) => T_JSON): T_JSON | undefined
"""))

        XCTAssertTrue(actual.contains("""
export function Optional_decode<T, T_JSON>(json: T_JSON | null, T_decode: (json: T_JSON) => T): T | null
"""))

        XCTAssertTrue(actual.contains("""
export function Optional_encode<T, T_JSON>(entity: T | null, T_encode: (entity: T) => T_JSON): T_JSON | null
"""))

        XCTAssertTrue(actual.contains("""
export function Array_decode<T, T_JSON>(json: T_JSON[], T_decode: (json: T_JSON) => T): T[]
"""))

        XCTAssertTrue(actual.contains("""
export function Array_encode<T, T_JSON>(entity: T[], T_encode: (entity: T) => T_JSON): T_JSON[]
"""))

        XCTAssertTrue(actual.contains("""
export function Dictionary_decode<T, T_JSON>(json: { [key: string]: T_JSON; }, T_decode: (json: T_JSON) => T): { [key: string]: T; }
"""))

        XCTAssertTrue(actual.contains("""
export function Dictionary_encode<T, T_JSON>(entity: { [key: string]: T; }, T_encode: (entity: T) => T_JSON): { [key: string]: T_JSON; }
"""))
    }
}
