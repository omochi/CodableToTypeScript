import XCTest
import SwiftTypeReader
import CodableToTypeScript

class GenerateTestCaseBase: XCTestCase {
    enum Prints {
        case none
        case one
        case all
    }
    // debug
    var prints: Prints { .none }

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
            let module = try Reader(context: context).read(source: source)

            let gen = CodeGenerator(typeMap: typeMap ?? .default)

            if case .all = prints {
                for swType in module.types {
                    print("// \(swType.name)")
                    let code = try gen.generateTypeDeclarationFile(type: swType)
                    print(code)
                }
            }

            let swType = try typeSelector(module: module)
            let code = try gen.generateTypeDeclarationFile(type: swType)

            if case .one = prints {
                print(code)
            }

            let actual = code.description

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
