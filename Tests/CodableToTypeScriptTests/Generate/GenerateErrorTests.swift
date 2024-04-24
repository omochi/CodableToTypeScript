import XCTest
import CodableToTypeScript
import SwiftTypeReader
import TypeScriptAST

final class GenerateErrorTests: GenerateTestCaseBase {
    func testStruct() throws {
        XCTAssertThrowsError(try assertGenerate(
            source: """
            struct S {
                var a: A
                struct T {
                    var b: B
                }
            }
            """
        )) { (error) in
            XCTAssertEqual("\(error)", """
            S.a: Error type can't be evaluated: A
            S.T.b: Error type can't be evaluated: B
            """)
        }
    }

    func testPackageGenerator() throws {
        let context = Context()
        let module = Reader(context: context).read(source: """
        struct S {
            var t: T
        }
        """, file: URL(fileURLWithPath: "A.swift")).module
        _ = Reader(context: context, module: module).read(source: """
        struct T {
            var b: B
        }
        """, file: URL(fileURLWithPath: "B.swift"))

        let generator = PackageGenerator(
            context: context,
            symbols: SymbolTable(),
            importFileExtension: .js,
            outputDirectory: URL(fileURLWithPath: "/dev/null", isDirectory: true)
        )
        XCTAssertThrowsError(try generator.generate(modules: [module])) { (error) in
            XCTAssertEqual("\(error)", """
            B.swift.T.b: Error type can't be evaluated: B
            A.swift.S.t.b: Error type can't be evaluated: B
            """)
        }
    }

    func testEnum() throws {
        XCTAssertThrowsError(try assertGenerate(
            source: """
            enum S {
                case a(A)
                enum T {
                    case b(B)
                }
            }
            """
        )) { (error) in
            XCTAssertEqual("\(error)", """
            S.a._0: Error type can't be evaluated: A
            S.T.b._0: Error type can't be evaluated: B
            """)
        }
    }
}
