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

        _ = Reader(
            context: context,
            module: context.getOrCreateModule(name: "A")
        ).read(source: """
        struct UnusedA: Codable {}
        """, file: URL(fileURLWithPath: "A+Unused.swift"))

        _ = Reader(
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
        struct NotTSConvertibleC: Codable {
            var a: UnknownType
        }
        """, file: URL(fileURLWithPath: "C.swift"))

        let dModule = Reader(
            context: context,
            module: context.getOrCreateModule(name: "D")
        ).read(source: """
        import B

        struct D: Codable {
            var b: B
        }
        """, file: URL(fileURLWithPath: "D.swift")).module

        let generator = PackageGenerator(
            context: context,
            symbols: SymbolTable(),
            importFileExtension: .js,
            outputDirectory: URL(fileURLWithPath: "/dev/null", isDirectory: true)
        )
        let result = try generator.generate(modules: [dModule])
        let rootElements = result.entries.flatMap(\.source.elements)
        XCTAssertTrue(rootElements.contains(where: { element in
            return element.asDecl?.asType?.name == "A"
        }))
        XCTAssertFalse(rootElements.contains(where: { element in
            return element.asDecl?.asType?.name == "UnusedA"
        }))
        XCTAssertTrue(rootElements.contains(where: { element in
            return element.asDecl?.asType?.name == "B"
        }))
        XCTAssertFalse(rootElements.contains(where: { element in
            return element.asDecl?.asType?.name == "NotTSConvertibleC"
        }))
        XCTAssertTrue(rootElements.contains(where: { element in
            return element.asDecl?.asType?.name == "D"
        }))
    }

    func testCustomMappedTypeIngored() throws {
        let context = Context()
        let module = Reader(context: context).read(source: """
        struct AbsoluteURL: Codable, RawRepresentable {
            var rawValue: String

            func encode(to encoder: any Encoder) throws {
                var c = encoder.singleValueContainer()
                try c.encode(rawValue)
            }

            init(from decoder: any Decoder) throws {
                let c = try decoder.singleValueContainer()
                self.rawValue = try c.decode(RawValue.self)
            }
        }
        """, file: URL(fileURLWithPath: "A.swift")).module

        let typeMap = TypeMap(mapFunction: { stype in
            if stype.description == "AbsoluteURL" {
                return .identity(name: "string")
            }
            return nil
        })

        let generator = PackageGenerator(
            context: context,
            typeConverterProvider: TypeConverterProvider(typeMap: typeMap),
            symbols: SymbolTable(),
            importFileExtension: .js,
            outputDirectory: URL(fileURLWithPath: "/dev/null", isDirectory: true)
        )
        let result = try generator.generate(modules: [module])
        XCTAssertEqual(result.entries.count, 1) // helper library only
        let hasTSAbsoluteURL = result.entries.contains(where: { entry in
            entry.source.memberDeclaredNames.contains(where: { name in
                return name == "AbsoluteURL"
            })
        })
        XCTAssertFalse(hasTSAbsoluteURL)
    }
}
