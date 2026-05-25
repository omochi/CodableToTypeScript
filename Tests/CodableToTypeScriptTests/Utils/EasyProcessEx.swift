import Foundation
import Synchronization

extension EasyProcess {
    static func capture(path: URL, args: [String]) throws -> String {
        let outData: Mutex<Data> = Mutex(Data())
        let errData: Mutex<Data> = Mutex(Data())
        let process = EasyProcess(
            path: path,
            args: args,
            outSink: { chunk in
                outData.withLock { outData in
                    outData.append(chunk)
                }
            },
            errorSink: { chunk in
                errData.withLock { errData in
                    errData.append(chunk)
                }
            }
        )
        let status = try process.run()
        let out = String(data: outData.withLock { $0 }, encoding: .utf8) ?? ""
        let err = String(data: errData.withLock { $0 }, encoding: .utf8) ?? ""
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
