import Foundation
import TypeScriptAST

public struct PackageEntry {
    public init(
        file: URL,
        source: TSSourceFile
    ) {
        self.file = file
        self.source = source
    }
    
    public var file: URL
    public var source: TSSourceFile

    public func print() -> String {
        source.print()
    }

    public func serialize() -> Data {
        print().data(using: .utf8)!
    }
}
