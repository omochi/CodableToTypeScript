import Foundation
import SwiftTypeReader
import TSCodeModule

public struct CodeGenerator {
    public static let defaultStandardTypes: Set<String> = [
        "void",
        "null",
        "undefined",
        "number",
        "string",
        "boolean",
    ]

    public var typeMap: TypeMap
    public var standardTypes: Set<String>
    public var importFrom: String

    public init(
        typeMap: TypeMap,
        standardTypes: Set<String> = Self.defaultStandardTypes,
        importFrom: String = ".."
    ) {
        self.typeMap = typeMap
        self.standardTypes = standardTypes
        self.importFrom = importFrom
    }

    public func callAsFunction(type: SType) throws -> TSCode {
        try Impl(
            typeMap: typeMap,
            standardTypes: standardTypes,
            importFrom: importFrom,
            type: type
        ).run()
    }
}

private final class Impl {
    init(
        typeMap: TypeMap,
        standardTypes: Set<String>,
        importFrom: String,
        type: SType
    ) {
        self.typeMap = typeMap
        self.standardTypes = standardTypes
        self.importFrom = importFrom
        self.type = type
        self.code = TSCode(decls: [])
    }

    let typeMap: TypeMap
    let standardTypes: Set<String>
    let importFrom: String
    let type: SType
    var code: TSCode

    func run() throws -> TSCode {
        try convert(type: type)

        let deps = DependencyScanner(standardTypes: standardTypes)(code: code)

        if !deps.isEmpty {
            let importDecl = TSImportDecl(names: deps, from: importFrom)
            code.decls.insert(.importDecl(importDecl), at: 0)
        }

        return code
    }

    func convert(type: SType) throws {
        guard let type = type.regular else {
            return
        }
        switch type {
        case .enum(let type):
            let genericParameters = type.genericParameters.map { $0.name }
            let ret = try EnumConverter(typeMap: typeMap).convert(type: type)
            code.decls += ret.typeDecls.map {
                .typeDecl(
                    name: $0.name,
                    genericParameters: genericParameters,
                    type: $0.type
                )
            }
            code.decls += ret.customDecls.map { .custom($0) }
        case .struct(let type):
            let genericParameters = type.genericParameters.map { $0.name }
            let ret = try StructConverter(typeMap: typeMap).convert(type: type)
            code.decls += [
                .typeDecl(
                    name: type.name,
                    genericParameters: genericParameters,
                    type: .record(ret)
                )
            ]
        case .protocol,
             .genericParameter:
            return
        }
    }
}
