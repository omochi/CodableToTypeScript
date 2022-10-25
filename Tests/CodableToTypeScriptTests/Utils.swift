import SwiftTypeReader
import TSCodeModule
import XCTest
@testable import CodableToTypeScript

enum Utils {
    static func generate(
        source: String,
        typeMap: TypeMap? = nil,
        typeSelector: TypeSelector,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> TSCode {
        let result = try Reader().read(source: source)
        let swType = try typeSelector(module: result.module)
        return try CodeGenerator(typeMap: typeMap ?? .default)(type: swType)
    }
}

struct TypeSelector {
    var body: (SwiftTypeReader.Module) throws -> SType

    func callAsFunction(module: SwiftTypeReader.Module) throws -> SType {
        try body(module)
    }

    static func first(
        file: StaticString = #file,
        line: UInt = #line
    ) -> TypeSelector {
        predicate(
            { (_) in true },
            file: file, line: line
        )
    }

    static func predicate(
        _ body: @escaping (SType) -> Bool,
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
            { $0.name == name },
            file: file, line: line
        )
    }
}
