import XCTest
import SwiftTypeReader
import CodableToTypeScript
import TypeScriptAST

class GenerateTestCaseBase: XCTestCase {
    enum Prints {
        case none
        case one
        case all
    }
    // debug
    var prints: Prints { .none }

    func dateTypeMap() -> TypeMap {
        var typeMap = TypeMap()
        typeMap.table["Date"] = .coding(
            entityType: "Date", jsonType: "string",
            decode: "Date_decode", encode: "Date_encode"
        )
        return typeMap
    }

    func dateTypeExternal() -> ExternalReference {
        return ExternalReference(
            symbols: [
                "Date_decode", "Date_encode"
            ],
            code: """
            export function Date_decode(json: string): Date { throw 0; }
            export function Date_encode(date: Date): string { throw 0; }
            """
        )
    }

    func assertGenerate(
        context: Context? = nil,
        source: String,
        typeSelector: TypeSelector = .last(file: #file, line: #line),
        typeMap: TypeMap? = nil,
        typeConverterProvider: TypeConverterProvider? = nil,
        externalReference: ExternalReference? = nil,
        expecteds: [String] = [],
        unexpecteds: [String] = [],
        file: StaticString = #file,
        line: UInt = #line,
        function: StaticString = #function
    ) throws {
        let context = context ?? Context()

        try withExtendedLifetime(context) { context in
            let module = context.getOrCreateModule(name: "main")
            _ = try Reader(context: context, module: module)
                .read(source: source, file: URL(fileURLWithPath: "main.swift"))

            let typeMap = typeMap ?? .default

            let typeConverterProvider = typeConverterProvider ?? TypeConverterProvider(
                typeMap: typeMap
            )

            let packageTester = PackageBuildTester(
                context: context,
                typeConverterProvider: typeConverterProvider,
                externalReference: externalReference,
                file: file,
                line: line,
                function: function
            )

            let gen = packageTester.packageGenerator.codeGenerator

            func generate(type: any TypeDecl) throws -> TSSourceFile {
                let code = try gen.converter(for: type.declaredInterfaceType).source()
                let imports = try code.buildAutoImportDecls(
                    from: URL(fileURLWithPath: "test.ts"),
                    symbolTable: SymbolTable(),
                    fileExtension: packageTester.packageGenerator.importFileExtension,
                    defaultFile: ".."
                )
                code.replaceImportDecls(imports)
                return code
            }

            if case .all = prints {
                for swType in module.types {
                    print("// \(swType.typeName ?? "?")")
                    let code = try generate(type: swType)
                    print(code.print())
                }
            }

            let swType = try typeSelector(module: module)
            let code = try generate(type: swType)

            if case .one = prints {
                print(code.print())
            }

            let actual = code.print()

            assertText(
                text: actual,
                expecteds: expecteds,
                unexpecteds: unexpecteds,
                file: file, line: line
            )

            XCTAssertNoThrow(
                try packageTester.build(module: module),
                "generate and build typescript: dir=\(packageTester.directory.path)",
                file: file, line: line
            )
        }
    }
}
