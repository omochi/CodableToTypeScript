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
    var prints: Prints { .one }

    func assertGenerate(
        source: String,
        typeSelector: TypeSelector = .last(file: #file, line: #line),
        typeMap: TypeMap? = nil,
        expecteds: [String] = [],
        unexpecteds: [String] = [],
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        try withExtendedLifetime(Context()) { context in
            let module = context.getOrCreateModule(name: "main")
            _ = try Reader(context: context, module: module)
                .read(source: source, file: URL(fileURLWithPath: "main.swift"))

            let typeConverterProvider = TypeConverterProvider(
                typeMap: typeMap ?? .default
            )

            let gen = CodeGenerator(
                context: context,
                typeConverterProvider: typeConverterProvider
            )

            func generate(type: any TypeDecl) throws -> TSSourceFile {
                let code = try gen.converter(for: type.declaredInterfaceType).source()
                let imports = try code.buildAutoImportDecls(
                    symbolTable: SymbolTable(),
                    defaultFile: ".."
                )
                code.replaceImportDecls(imports)
                return code
            }

            if case .all = prints {
                for swType in module.types {
                    print("// \(swType.name)")
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

            for expected in expecteds {
                if !actual.contains(expected) {
                    XCTFail(
                        "No expected text: \(expected)",
                        file: file, line: line
                    )
                }
            }
            for unexpected in unexpecteds {
                if actual.contains(unexpected) {
                    XCTFail(
                        "Unexpected text: \(unexpected)",
                        file: file, line: line
                    )
                }
            }
        }
    }
}
