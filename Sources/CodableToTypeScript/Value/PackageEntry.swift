import Foundation
import TypeScriptAST

public struct PackageEntry {
    public init(
        file: String,
        source: TSSourceFile
    ) {
        self.file = file
        self.source = source
    }
    
    public var file: String
    public var source: TSSourceFile
}
