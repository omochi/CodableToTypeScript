import Foundation
import SwiftTypeReader
import TypeScriptAST

public final class PackageGenerator {
    public init(
        context: SwiftTypeReader.Context,
        fileManager: FileManager = .default,
        typeConverterProvider: TypeConverterProvider = TypeConverterProvider(),
        symbols: SymbolTable,
        importFileExtension: ImportFileExtension,
        outputDirectory: URL
    ) {
        self.context = context
        self.fileManager = fileManager
        self.codeGenerator = CodeGenerator(
            context: context,
            typeConverterProvider: typeConverterProvider
        )
        self.symbols = symbols
        self.importFileExtension = importFileExtension
        self.outputDirectory = outputDirectory
    }

    public let context: SwiftTypeReader.Context
    public let fileManager: FileManager
    public let codeGenerator: CodeGenerator
    public let symbols: SymbolTable
    public let importFileExtension: ImportFileExtension
    public let outputDirectory: URL
    public var didGenerateEntry: ((SourceFile, PackageEntry) throws -> Void)?
    public var didWrite: ((URL, Data) throws -> Void)?

    public func generate(modules: [Module]) throws -> [PackageEntry] {
        var entries: [PackageEntry] = [
            PackageEntry(
                file: path("common.ts"),
                source: codeGenerator.generateHelperLibrary()
            )
        ]

        for module in modules {
            for source in module.sources {
                let tsSource = try codeGenerator.convert(source: source)

                let entry = PackageEntry(
                    file: try tsPath(module: module, file: source.file),
                    source: tsSource
                )
                entries.append(entry)
                try didGenerateEntry?(source, entry)
            }
        }

        var symbols = self.symbols

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

    private func tsPath(module: Module, file: URL) throws -> URL {
        if file.baseURL == nil {
            throw MessageError("needs relative path: \(file.path)")
        }

        return self.path(
            module.name + "/" +
            file.replacingPathExtension("ts").relativePath
        )
    }

    private func path(_ name: String) -> URL {
        outputDirectory.appendingPathComponent(name)
    }

    public func write(
        entry: PackageEntry
    ) throws {
        let path = entry.file
        try fileManager.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)

        let data = entry.source.print().data(using: .utf8)!

        if let old = try? Data(contentsOf: path),
           old == data
        {
            return
        }

        try data.write(to: path, options: .atomic)
        try didWrite?(path, data)
    }

    public func write(
        entries: [PackageEntry]
    ) throws {
        for entry in entries {
            try write(entry: entry)
        }
    }
}
