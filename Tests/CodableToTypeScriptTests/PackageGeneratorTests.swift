import XCTest
import SwiftTypeReader
import TypeScriptAST
import CodableToTypeScript

final class PackageGeneratorTests: XCTestCase {
    func testEmptyModule() throws {
        let context = Context()
        let module = Reader(context: context).read(source: """
        protocol P {
            func f()
        }
        """, file: URL(fileURLWithPath: "A.swift")).module

        // case1: empty for C2TS
        let generator = PackageGenerator(
            context: context,
            symbols: SymbolTable(),
            importFileExtension: .js,
            outputDirectory: URL(fileURLWithPath: "/dev/null", isDirectory: true)
        )
        let result = try generator.generate(modules: [module])
        XCTAssertEqual(result.entries.count, 1) // helper library anytime generated

        // case2: empty for C2TS, but not for the user
        let expectation = self.expectation(description: "didConvertSource called")
        generator.didConvertSource = { source, entry in
            entry.source.elements.append(TSCustomDecl(text: "/* hello */"))
            expectation.fulfill()
        }
        let result2 = try generator.generate(modules: [module])

        wait(for: [expectation], timeout: 3)
        XCTAssertEqual(result2.entries.count, 2)
    }

    func testDependentModule() throws {
        let context = Context()

        _ = Reader(
            context: context,
            module: context.getOrCreateModule(name: "A")
        ).read(source: """
        struct A: Codable {}
        """, file: URL(fileURLWithPath: "A.swift"))

        let bModule = Reader(
            context: context,
            module: context.getOrCreateModule(name: "B")
        ).read(source: """
        import A

        struct B: Codable {
            var a: A
        }
        """, file: URL(fileURLWithPath: "B.swift")).module

        _ = Reader(
            context: context,
            module: context.getOrCreateModule(name: "C")
        ).read(source: """
        struct Unused: Codable {}
        """, file: URL(fileURLWithPath: "C.swift"))

        let generator = PackageGenerator(
            context: context,
            symbols: SymbolTable(),
            importFileExtension: .js,
            outputDirectory: URL(fileURLWithPath: "/dev/null", isDirectory: true)
        )
        let result = try generator.generate(modules: [bModule])
        let rootElements = result.entries.flatMap(\.source.elements)
        XCTAssertTrue(rootElements.contains(where: { element in
            return element.asDecl?.asType?.name == "A"
        }))
        XCTAssertTrue(rootElements.contains(where: { element in
            return element.asDecl?.asType?.name == "B"
        }))
        XCTAssertFalse(rootElements.contains(where: { element in
            return element.asDecl?.asType?.name == "Unused"
        }))
    }
}
