import XCTest
import CodableToTypeScript

class GenerateTestCaseBase: XCTestCase {
    // debug
    var prints: Bool { true }

    func assertGenerate(
        source: String,
        typeSelector: TypeSelector = .first(file: #file, line: #line),
        typeMap: TypeMap? = nil,
        expecteds: [String] = [],
        unexpecteds: [String] = [],
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let tsCode = try Utils.generate(
            source: source,
            typeMap: typeMap,
            typeSelector: typeSelector,
            file: file, line: line
        )
        let actual = tsCode.description
        if prints {
            print(actual)
        }
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
