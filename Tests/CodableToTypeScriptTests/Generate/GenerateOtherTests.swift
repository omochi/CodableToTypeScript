import XCTest
import CodableToTypeScript

final class GenerateOtherTests: GenerateTestCaseBase {
    func testTranspileUnresolvedRef() throws {
        try assertGenerate(
            source: """
struct Q {
    var id: ID
    var ids: [ID]
}
""",
            expecteds: ["""
export type Q = {
    id: ID;
    ids: ID[];
};
"""]
        )
    }
}
