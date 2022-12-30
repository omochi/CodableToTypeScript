import Foundation

#if canImport(Glibc)
@_exported import Glibc
#else
@_exported import Darwin.C
#endif

enum Env {
    static func get(_ name: String) -> String? {
        return ProcessInfo.processInfo.environment[name]
    }

    static func set(_ name: String, _ value: String) throws {
        guard setenv(name, value, 1) == 0 else {
            throw MessageError("setenv failed: \(errno)")
        }
    }

    static func addPath(_ path: String) throws {
        var paths = (get("PATH") ?? "").components(separatedBy: ":")

        if paths.contains(path) { return }

        paths.append(path)

        try set("PATH", paths.joined(separator: ":"))
    }
}
