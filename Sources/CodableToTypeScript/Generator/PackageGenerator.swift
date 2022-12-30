import Foundation
import SwiftTypeReader
import TypeScriptAST

public final class PackageGenerator {
    public init(
        context: SwiftTypeReader.Context,
        fileManager: FileManager = .default,
        typeConverterProvider: TypeConverterProvider = TypeConverterProvider(),
        standardLibrarySymbols: Set<String> = SymbolTable.standardLibrarySymbols,
        importFileExtension: ImportFileExtension,
        outputDirectory: URL
    ) {
        self.context = context
        self.fileManager = fileManager
        self.codeGenerator = CodeGenerator(
            context: context,
            typeConverterProvider: typeConverterProvider
        )
        self.standardLibrarySymbols = standardLibrarySymbols
        self.importFileExtension = importFileExtension
        self.outputDirectory = outputDirectory
    }

    public let context: SwiftTypeReader.Context
    public let fileManager: FileManager
    public let codeGenerator: CodeGenerator
    public let standardLibrarySymbols: Set<String>
    public let importFileExtension: ImportFileExtension
    public let outputDirectory: URL
    public var didWrite: ((URL, Data) -> Void)?

    public func generate(modules: [Module]) throws -> [PackageEntry] {
        var entries: [PackageEntry] = [
            PackageEntry(
                file: "common.ts",
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
                    file: "\(name).ts",
                    source: source
                )
                entries.append(entry)
            }
        }

        var symbols = SymbolTable(standardLibrarySymbols: standardLibrarySymbols)

        for entry in entries {
            symbols.add(source: entry.source, file: entry.file)
        }

        for entry in entries {
            let source = entry.source
            let imports = try source.buildAutoImportDecls(
                from: entry.file,
                symbolTable: symbols,
                fileExtension: importFileExtension
            )
            source.replaceImportDecls(imports)
        }

        return entries
    }

    public func write(
        entry: PackageEntry
    ) throws {
        let path = outputDirectory.appendingPathComponent(entry.file)
        try fileManager.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)

        let data = entry.source.print().data(using: .utf8)!

        if let old = try? Data(contentsOf: path),
           old == data
        {
            return
        }

        try data.write(to: path, options: .atomic)
        didWrite?(path, data)
    }

    public func write(
        entries: [PackageEntry]
    ) throws {
        for entry in entries {
            try write(entry: entry)
        }
    }
}
