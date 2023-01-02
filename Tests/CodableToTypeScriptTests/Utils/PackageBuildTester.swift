import Foundation
import CodableToTypeScript
import SwiftTypeReader
import TypeScriptAST

struct PackageBuildTester {
    private static func makeLaunchName() -> String {
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMddHHmmss"
        return formatter.string(from: now)
    }

    private static func addPath() throws {
        if isAddPathDone { return }
        isAddPathDone = true
        try Env.addPath("/usr/local/bin")
    }
    private static var isAddPathDone = false

    private static func launchDirectory(fileManager: FileManager) -> URL {
        if let dir = launchDirectoryCache { return dir }

        let dir = fileManager.temporaryDirectory
            .appendingPathComponent("CodableToTypeScriptTests")
            .appendingPathComponent(makeLaunchName())
        print("[PackageBuildTester]: \(dir.path)")
        launchDirectoryCache = dir
        return dir
    }
    private static var launchDirectoryCache: URL?

    init(
        fileManager: FileManager = .default,
        context: Context,
        typeConverterProvider: TypeConverterProvider,
        externalReference: ExternalReference?,
        file: StaticString,
        line: UInt,
        function: StaticString
    ) {
        self.context = context
        self.typeConverterProvider = typeConverterProvider
        self.fileManager = fileManager

        self.directory = Self.launchDirectory(fileManager: fileManager)
            .appendingPathComponent(Self.testName(file: file))
            .appendingPathComponent(Self.funcName(function: function) + "L\(line)")

        self.externalReference = externalReference

        let outDir = directory.appendingPathComponent("src")

        var symbols = SymbolTable()
        for symbol in externalReference?.symbols ?? [] {
            symbols.add(
                symbol: symbol,
                file: .file(outDir.appendingPathComponent("externals.ts"))
            )
        }

        self.packageGenerator = PackageGenerator(
            context: context,
            fileManager: fileManager,
            typeConverterProvider: typeConverterProvider,
            symbols: symbols,
            importFileExtension: .none,
            outputDirectory: outDir
        )

        self.isSkipped = Env.get("SKIP_TSC") != nil
    }

    static func testName(file: StaticString) -> String {
        let name = (file.description as NSString).lastPathComponent
        return (name as NSString).deletingPathExtension
    }

    static func funcName(function: StaticString) -> String {
        var s = function.description
        if let i = s.firstIndex(of: "(") {
            s = String(s[..<i])
        }
        return s
    }

    var context: Context
    var typeConverterProvider: TypeConverterProvider
    var fileManager: FileManager
    var directory: URL
    var externalReference: ExternalReference?
    var packageGenerator: PackageGenerator
    var isSkipped: Bool

    func build(module: Module) throws {
        if isSkipped { return }
        
        let entries = try packageGenerator.generate(modules: [module])
        try packageGenerator.write(entries: entries)
        try writeExternals()
        try writeTSConfig()
        try buildTypeScript()
    }

    private func writeExternals() throws {
        guard let externalReference else { return }
        let data = externalReference.code.data(using: .utf8)!
        try data.write(
            to: packageGenerator.outputDirectory.appendingPathComponent("externals.ts"),
            options: .atomic
        )
    }

    private func writeTSConfig() throws {
        let json = """
        {
          "compilerOptions": {
            "outDir": "out",
            "module": "commonjs",
            "strict": true,
            "target": "es2015",
          },
        }

        """

        let data = json.data(using: .utf8)!
        try data.write(to: directory.appendingPathComponent("tsconfig.json"), options: .atomic)
    }

    private func buildTypeScript() throws {
        guard fileManager.changeCurrentDirectoryPath(directory.path) else {
            throw MessageError("failed to chdir: \(directory.path)")
        }
        try Self.addPath()
        try EasyProcess.command(["npx", "tsc"])
    }
}
