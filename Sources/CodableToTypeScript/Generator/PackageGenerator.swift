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
        typeScriptExtension: String = "ts",
        pathPrefixReplacements: PathPrefixReplacements = []
    ) {
        self.context = context
        self.fileManager = fileManager
        self.codeGenerator = CodeGenerator(
            context: context,
            typeConverterProvider: typeConverterProvider
        )
        self.symbols = symbols
        self.importFileExtension = importFileExtension
        self.outputDirectory = URL(
            fileURLWithPath: outputDirectory.path,
            isDirectory: true, relativeTo: outputDirectory.baseURL
        )
        self.typeScriptExtension = typeScriptExtension
        self.pathPrefixReplacements = pathPrefixReplacements
    }

    public let context: SwiftTypeReader.Context
    public let fileManager: FileManager
    public let codeGenerator: CodeGenerator
    public let symbols: SymbolTable
    public let importFileExtension: ImportFileExtension
    public let outputDirectory: URL
    public let typeScriptExtension: String
    public let pathPrefixReplacements: PathPrefixReplacements
    @available(*, deprecated, renamed: "didConvertSource")
    public var didGenerateEntry: ((SourceFile, PackageEntry) throws -> Void)? {
        get { didConvertSource }
        set { didConvertSource = newValue }
    }
    public var didConvertSource: ((SourceFile, PackageEntry) throws -> Void)?

    public var didWrite: ((URL, Data) throws -> Void)?

    public struct GenerateResult {
        public var entries: [PackageEntry]
        public var symbols: SymbolTable
    }

    public func generate(modules: [Module]) throws -> GenerateResult {
        let helperEntry = PackageEntry(
            file: self.path("common.\(typeScriptExtension)"),
            source: codeGenerator.generateHelperLibrary()
        )

        var symbolToSource: [String: SourceFile] = [:]
        var convertedSources: [SourceFile: TSSourceFile] = [:]

        // collect symbols included in for each swift source file
        for module in context.modules.filter({ $0 !== context.swiftModule }) {
            for source in module.sources {
                guard let tsSource = try? codeGenerator.convert(source: source) else {
                    continue
                }
                convertedSources[source] = tsSource
                for declaredName in tsSource.memberDeclaredNames {
                    symbolToSource[declaredName] = source
                }
            }
        }

        // convert collected symbols to SymbolTable for use of buildAutoImportDecls
        var allSymbols = self.symbols
        allSymbols.add(source: helperEntry.source, file: helperEntry.file)
        for (symbol, source) in symbolToSource {
            allSymbols.add(
                symbol: symbol,
                file: .file(try tsPath(module: source.module, file: source.file))
            )
        }

        var targetSources: [SourceFile] = modules.flatMap(\.sources)
        var generatedSources: Set<SourceFile> = []
        var generatedEntries: [PackageEntry] = [helperEntry]

        try withErrorCollector { collect in
            while let source = targetSources.popLast() {
                guard generatedSources.insert(source).inserted else {
                    continue
                }

                collect(at: source.file.lastPathComponent) {
                    let tsSource = try convertedSources[source] ?? (codeGenerator.convert(source: source))

                    let entry = PackageEntry(
                        file: try tsPath(module: source.module, file: source.file),
                        source: tsSource
                    )
                    try didConvertSource?(source, entry)
                    if entry.isEmpty {
                        return
                    }

                    generatedEntries.append(.init(
                        file: entry.file,
                        source: entry.source
                    ))

                    let imports = try tsSource.buildAutoImportDecls(
                        from: entry.file,
                        symbolTable: allSymbols,
                        fileExtension: importFileExtension,
                        pathPrefixReplacements: pathPrefixReplacements
                    )
                    tsSource.replaceImportDecls(imports)
                    for importedSymbolName in imports.flatMap(\.names) {
                        // Add a file that is used but not included in the generation target
                        if let source = symbolToSource[importedSymbolName], !generatedSources.contains(source) {
                            targetSources.append(source)
                        }
                    }
                }
            }
        }

        return GenerateResult(
            entries: generatedEntries,
            symbols: allSymbols
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
        return URL(fileURLWithPath: name, relativeTo: outputDirectory)
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

extension PackageEntry {
    fileprivate var isEmpty: Bool {
        source.elements.isEmpty
    }
}
