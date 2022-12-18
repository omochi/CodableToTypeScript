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
        file: StaticString = #file, line: UInt = #line
    ) -> TypeSelector {
        TypeSelector { (module) in
            try XCTUnwrap(
                module.types.first(where: body),
                "predicate",
                file: file, line: line
            )
        }
    }

    static func name(
        _ name: String,
        recursive: Bool = false,
        file: StaticString = #file, line: UInt = #line
    ) -> TypeSelector {
        func pred(decl: any TypeDecl) -> Bool {
            return decl.valueName == name
        }

        if recursive {
            return self.recursivePredicate(pred, file: file, line: line)
        } else {
            return self.predicate(pred, file: file, line: line)
        }
    }

    static func recursivePredicate(
        _ body: @escaping (any TypeDecl) -> Bool,
        file: StaticString = #file, line: UInt = #line
    ) -> TypeSelector {
        TypeSelector { (module) in
            var result: (any TypeDecl)? = nil

            module.walkTypeDecls { (decl) in
                guard result == nil else { return false }

                if body(decl) {
                    result = decl
                    return false
                }

                return true
            }

            return try XCTUnwrap(
                result, "recursivePredicate",
                file: file, line: line
            )
        }
    }
}
