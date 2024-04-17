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
        struct EntryWithSymbols {
            var entry: PackageEntry
            var symbols: SymbolTable
            var isGenerateTarget: Bool
            init(
                file: URL,
                source: TSSourceFile,
                isGenerateTarget: Bool
            ) {
                self.entry = PackageEntry(file: file, source: source)
                var symbols = SymbolTable(standardLibrarySymbols: [])
                symbols.add(source: source, file: file)
                self.symbols = symbols
                self.isGenerateTarget = isGenerateTarget
            }
        }

        let helperEntry = EntryWithSymbols(
            file: self.path("common.\(typeScriptExtension)"),
            source: codeGenerator.generateHelperLibrary(),
            isGenerateTarget: true
        )

        var entries: [EntryWithSymbols] = [helperEntry]

        try withErrorCollector { collect in
            for module in context.modules.filter({ $0 !== context.swiftModule }) {
                let isGenerateTargetModule = modules.contains(where: { $0 === module })

                for source in module.sources {
                    collect {
                        let tsSource = try codeGenerator.convert(source: source)

                        let entry = PackageEntry(
                            file: try tsPath(module: module, file: source.file),
                            source: tsSource
                        )
                        try didConvertSource?(source, entry)

                        if !entry.source.elements.isEmpty {
                            entries.append(.init(
                                file: entry.file,
                                source: entry.source,
                                isGenerateTarget: isGenerateTargetModule
                            ))
                        }
                    }
                }
            }
        }

        let allSymbols = try {
            var ret = self.symbols
            try withErrorCollector { collect in
                for entry in entries {
                    collect {
                        try ret.formUnion(entry.symbols)
                    }
                }
            }
            return ret
        }()

        var importedSymbols: Set<String> = []
        var generatedEntries: [EntryWithSymbols] = []

        func generateEntry(_ entry: EntryWithSymbols) throws {
            let source = entry.entry.source
            let imports = try source.buildAutoImportDecls(
                from: entry.entry.file,
                symbolTable: allSymbols,
                fileExtension: importFileExtension
            )
            importedSymbols.formUnion(imports.flatMap(\.names))
            source.replaceImportDecls(imports)
            generatedEntries.append(entry)
        }

        try withErrorCollector { collect in
            for entry in entries where entry.isGenerateTarget {
                collect(at: "\(entry.entry.file.relativePath)") {
                    try generateEntry(entry)
                }
            }
        }

        try withErrorCollector { collect in
            var dirty = true
            while dirty {
                dirty = false

                let notGeneratedButNeededSymbols = {
                    var ret = importedSymbols
                    for entry in generatedEntries {
                        ret.subtract(entry.symbols.table.keys)
                    }
                    return ret
                }()

                
                for entry in entries where !entry.isGenerateTarget {
                    if entry.symbols.table.keys.contains(where: {
                        notGeneratedButNeededSymbols.contains($0)
                    }) {
                        collect(at: "\(entry.entry.file.relativePath)") {
                            try generateEntry(entry)
                            dirty = true
                        }
                    }
                }
            }
        }

        return GenerateResult(
            entries: generatedEntries.map(\.entry),
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
        return URL(fileURLWithPath: name, relativeTo: outputDirectory.appendingPathComponent("/"))
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

extension SymbolTable {
    fileprivate mutating func formUnion(_ other: SymbolTable) throws {
        try self.table.merge(other.table) { (a, b) in
            throw MessageError("symbol conflict! between \(a) and \(b)")
        }
    }
}
