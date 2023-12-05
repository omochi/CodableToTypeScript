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

        let generator = PackageGenerator(
            context: context,
            symbols: SymbolTable(),
            importFileExtension: .js,
            outputDirectory: URL(fileURLWithPath: "/dev/null", isDirectory: true)
        )
        let result = try generator.generate(modules: [module])
        XCTAssertEqual(result.entries.count, 1) // helper library anytime generated

        let expectation = self.expectation(description: "didGenerateEntry called")
        generator.didGenerateEntry = { source, entry in
            entry.source.elements.append(TSCustomDecl(text: "/* hello */"))
            expectation.fulfill()
        }
        let result2 = try generator.generate(modules: [module])

        wait(for: [expectation])
        XCTAssertEqual(result2.entries.count, 2)
    }
}
