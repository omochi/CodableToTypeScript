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
    var prints: Prints { .all }

    func assertGenerate(
        context: Context? = nil,
        source: String,
        typeSelector: TypeSelector = .last(file: #file, line: #line),
        typeMap: TypeMap? = nil,
        typeConverterProvider: TypeConverterProvider? = nil,
        expecteds: [String] = [],
        unexpecteds: [String] = [],
        file: StaticString = #file,
        line: UInt = #line
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
        }
    }
}
