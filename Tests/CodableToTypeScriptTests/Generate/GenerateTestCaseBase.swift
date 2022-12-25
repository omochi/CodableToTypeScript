import XCTest
import SwiftTypeReader
import CodableToTypeScript
import TypeScriptAST

struct AssertGenerateResult {
    var generated: String
    var failureExpecteds: [String] = []
    var failureUnexpecteds: [String] = []
    var file: StaticString
    var line: UInt

    func assert() {
        if failureExpecteds.isEmpty,
           failureUnexpecteds.isEmpty
        {
            return
        }

        var strs: [String] = []
        if !failureExpecteds.isEmpty {
            let heads = failureExpecteds.map { head($0).debugDescription }
            strs.append("No expected texts: " + heads.joined(separator: ", "))
        }

        if !failureUnexpecteds.isEmpty {
            let heads = failureUnexpecteds.map { head($0).debugDescription }
            strs.append("Unexpected texts: " + heads.joined(separator: ", "))
        }

        strs.append("Generated:\n" + generated)

        let message = strs.joined(separator: "; ")
        XCTFail(message, file: file, line: line)
    }

    func head(_ string: String) -> String {
        let lines = string.split(whereSeparator: { $0.isNewline })
        guard var head = lines.first else { return "" }
        if lines.count >= 2 {
            head += "..."
        }
        return String(head)
    }
}

class GenerateTestCaseBase: XCTestCase {
    enum Prints {
        case none
        case one
        case all
    }
    // debug
    var prints: Prints { .none }

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

            var result = AssertGenerateResult(generated: actual, file: file, line: line)

            for expected in expecteds {
                if !actual.contains(expected) {
                    result.failureExpecteds.append(expected)
                }
            }

            for unexpected in unexpecteds {
                if actual.contains(unexpected) {
                    result.failureUnexpecteds.append(unexpected)
                }
            }

            result.assert()
        }
    }
}
