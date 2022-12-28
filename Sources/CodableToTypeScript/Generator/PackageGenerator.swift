import Foundation
import SwiftTypeReader
import TypeScriptAST

public final class PackageGenerator {
    public init(
        context: SwiftTypeReader.Context,
        fileManager: FileManager = .default,
        typeConverterProvider: TypeConverterProvider = TypeConverterProvider(),
        standardLibrarySymbols: Set<String> = SymbolTable.standardLibrarySymbols,
        outputDirectory: URL
    ) {
        self.context = context
        self.fileManager = fileManager
        self.codeGenerator = CodeGenerator(
            context: context,
            typeConverterProvider: typeConverterProvider
        )
        self.standardLibrarySymbols = standardLibrarySymbols
        self.outputDirectory = outputDirectory
    }

    public let context: SwiftTypeReader.Context
    public let fileManager: FileManager
    public let codeGenerator: CodeGenerator
    public let standardLibrarySymbols: Set<String>
    public let outputDirectory: URL

    public func generate(modules: [Module]) throws -> [PackageEntry] {
        var entries: [PackageEntry] = [
            PackageEntry(
                file: URL(fileURLWithPath: "common.js"),
                source: codeGenerator.generateHelperLibrary()
            )
        ]

        for module in modules {
            for type in module.types {
                let typeConverter = try codeGenerator.converter(
                    for: type.declaredInterfaceType
                )

                let name = try typeConverter.name(for: .entity)
                let source = try typeConverter.source()

                let entry = PackageEntry(
                    file: URL(fileURLWithPath: "\(name).js"),
                    source: source
                )
                entries.append(entry)
            }
        }

        var symbols = SymbolTable(standardLibrarySymbols: standardLibrarySymbols)

        for entry in entries {
            symbols.add(source: entry.source, file: entry.file.relativePath)
        }

        for index in entries.indices {
            var source = entries[index].source
            let imports = try source.buildAutoImportDecls(symbolTable: symbols)
            source.replaceImportDecls(imports)
            entries[index].source = source
        }

        return entries
    }

    public func write(entry: PackageEntry) throws {
        let path = outputDirectory.appendingPathComponent(entry.file.relativePath)
        try fileManager.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)

        let data = entry.source.print().data(using: .utf8)!

        if let old = try? Data(contentsOf: path),
           old == data
        {
            return
        }

        try data.write(to: path, options: .atomic)
    }
}
