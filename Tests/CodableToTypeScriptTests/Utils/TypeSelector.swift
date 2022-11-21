import XCTest
import SwiftTypeReader

struct TypeSelector {
    var body: (SwiftTypeReader.Module) throws -> any TypeDecl

    func callAsFunction(module: SwiftTypeReader.Module) throws -> any TypeDecl {
        try body(module)
    }

    static func last(
        file: StaticString = #file,
        line: UInt = #line
    ) -> TypeSelector {
        TypeSelector { (module) in
            try XCTUnwrap(
                module.types.last,
                file: file, line: line
            )
        }
    }

    static func predicate(
        _ body: @escaping (any TypeDecl) -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) -> TypeSelector {
        TypeSelector { (module) in
            try XCTUnwrap(
                module.types.first(where: body),
                file: file, line: line
            )
        }
    }

    static func name(
        _ name: String,
        file: StaticString = #file,
        line: UInt = #line
    ) -> TypeSelector {
        return predicate(
            { (type) in
                type.valueName == name
            },
            file: file, line: line
        )
    }
}
