import Foundation

#if canImport(Glibc)
@_exported import Glibc
#else
@_exported import Darwin.C
#endif

enum Env {
    static func set(_ name: String, _ value: String) throws {
        guard setenv(name, value, 1) == 0 else {
            throw MessageError("setenv failed: \(errno)")
        }
    }

    static func addPath(_ path: String) throws {
        let current = ProcessInfo.processInfo.environment["PATH"] ?? ""

        var paths = current.components(separatedBy: ":")
        if paths.contains(path) { return }

        paths.append(path)

        try set("PATH", paths.joined(separator: ":"))
    }
}
