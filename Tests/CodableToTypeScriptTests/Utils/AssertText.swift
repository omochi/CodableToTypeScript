import XCTest

private func head(_ string: String) -> String {
    let lines = string.split(whereSeparator: { $0.isNewline })
    guard var head = lines.first else { return "" }
    if lines.count >= 2 {
        head += "..."
    }
    return String(head)
}

private struct AssertTextResult {
    var text: String
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

        strs.append("Generated:\n" + text)

        let message = strs.joined(separator: "; ")
        XCTFail(message, file: file, line: line)
    }
}

func assertText(
    text: String,
    expecteds: [String] = [],
    unexpecteds: [String] = [],
    file: StaticString = #file,
    line: UInt = #line
) {
    var result = AssertTextResult(text: text, file: file, line: line)

    for expected in expecteds {
        if !text.contains(expected) {
            result.failureExpecteds.append(expected)
        }
    }

    for unexpected in unexpecteds {
        if text.contains(unexpected) {
            result.failureUnexpecteds.append(unexpected)
        }
    }

    result.assert()
}
