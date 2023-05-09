import CodableToTypeScript
import Foundation
import SwiftTypeReader
import TypeScriptAST

public final class Generator {
    private let commonLibSource: TSSourceFile

    public init() {
        let tmpContext = SwiftTypeReader.Context()
        commonLibSource = CodeGenerator(context: tmpContext).generateHelperLibrary()
    }

    public func tsTypes(swiftSource: String) throws -> String {
        try withExtendedLifetime(SwiftTypeReader.Context()) { context in
            let reader = SwiftTypeReader.Reader(context: context)
            let swiftSource = reader.read(source: swiftSource, file: URL(fileURLWithPath: "/Types.swift"))

            let tsSource = try CodeGenerator(context: context)
                .convert(source: swiftSource)

            // collect all symbols
            var symbolTable = SymbolTable()
            symbolTable.add(source: commonLibSource, file: URL(fileURLWithPath: "/common.gen.ts"))
            symbolTable.add(source: tsSource, file: URL(fileURLWithPath: "/types.gen.ts"))

            // generate imports
            let imports = try tsSource.buildAutoImportDecls(
                from: URL(fileURLWithPath: "/types.gen.ts"),
                symbolTable: symbolTable,
                fileExtension: .js
            )
            tsSource.replaceImportDecls(imports)

            return tsSource.print()
        }
    }

    public func commonLib() -> String {
        commonLibSource.print()
    }
}
