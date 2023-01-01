import Foundation

extension EasyProcess {
    static func capture(path: URL, args: [String]) throws -> String {
        var outData = Data()
        var errData = Data()
        let process = EasyProcess(
            path: path,
            args: args,
            outSink: { outData.append($0) },
            errorSink: { errData.append($0) }
        )
        let status = try process.run()
        let out = String(data: outData, encoding: .utf8) ?? ""
        let err = String(data: errData, encoding: .utf8) ?? ""
        guard status == EXIT_SUCCESS else {
            throw MessageError("invalid status: \(status), err=\(err)")
        }
        return out
    }

    static func which(_ name: String) -> String? {
        guard let result = try? capture(
            path: URL(fileURLWithPath: "/usr/bin/which"),
            args: [name]
        ) else { return nil }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func command(_ args: [String]) throws {
        let name = args[0]
        guard let path = which(name) else {
            throw MessageError("command not found: \(name)")
        }

        let process = EasyProcess(
            path: URL(fileURLWithPath: path),
            args: Array(args[1...])
        )
        let status = try process.run()
        guard status == EXIT_SUCCESS else {
            throw MessageError("command failed: \(status), \(args)")
        }
    }
}
