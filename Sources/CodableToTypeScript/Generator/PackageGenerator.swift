import Foundation
import SwiftTypeReader
import TypeScriptAST

#if !os(WASI)
public final class PackageGenerator {
    public init(
        context: SwiftTypeReader.Context,
        fileManager: FileManager = .default,
        typeConverterProvider: TypeConverterProvider = TypeConverterProvider(),
        symbols: SymbolTable,
        importFileExtension: ImportFileExtension,
        outputDirectory: URL,
        typeScriptExtension: String = "ts"
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
        self.typeScriptExtension = typeScriptExtension
    }

    public let context: SwiftTypeReader.Context
    public let fileManager: FileManager
    public let codeGenerator: CodeGenerator
    public let symbols: SymbolTable
    public let importFileExtension: ImportFileExtension
    public let outputDirectory: URL
    public let typeScriptExtension: String
    public var didGenerateEntry: ((SourceFile, PackageEntry) throws -> Void)?
    public var didWrite: ((URL, Data) throws -> Void)?

    public struct GenerateResult {
        public var entries: [PackageEntry]
        public var symbols: SymbolTable
    }

    public func generate(modules: [Module]) throws -> GenerateResult {
        var entries: [PackageEntry] = [
            PackageEntry(
                file: self.path("common.\(typeScriptExtension)"),
                source: codeGenerator.generateHelperLibrary()
            )
        ]

        try withErrorCollector { collect in
            for module in modules {
                for source in module.sources {
                    collect {
                        let tsSource = try codeGenerator.convert(source: source)

                        if tsSource.elements.isEmpty { return }

                        let entry = PackageEntry(
                            file: try tsPath(module: module, file: source.file),
                            source: tsSource
                        )
                        entries.append(entry)
                        try didGenerateEntry?(source, entry)
                    }
                }
            }
        }

        var symbols = self.symbols

        for entry in entries {
            symbols.add(source: entry.source, file: entry.file)
        }

        try withErrorCollector { collect in
            for entry in entries {
                collect(at: "\(entry.file.lastPathComponent)") {
                    let source = entry.source
                    let imports = try source.buildAutoImportDecls(
                        from: entry.file,
                        symbolTable: symbols,
                        fileExtension: importFileExtension
                    )
                    source.replaceImportDecls(imports)
                }
            }
        }

        return GenerateResult(
            entries: entries,
            symbols: symbols
        )
    }

    private func tsPath(module: Module, file: URL) throws -> URL {
        if file.baseURL == nil {
            throw MessageError("needs relative path: \(file.path)")
        }

        return self.path(
            module.name + "/" +
            URLs.replacingPathExtension(of: file, to: typeScriptExtension).relativePath
        )
    }

    private func path(_ name: String) -> URL {
        outputDirectory.appendingPathComponent(name)
    }

    public func write(
        entry: PackageEntry
    ) throws {
        let path = entry.file
        let data = entry.serialize()

        if let old = try? Data(contentsOf: path),
           old == data
        {
            return
        }

        try fileManager.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
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
#endif
