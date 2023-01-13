import PackagePlugin
import Foundation

@main
struct CodegenPlugin: CommandPlugin {
    func performCommand(
        context: PluginContext,
        arguments: [String]
    ) async throws {
        let codegenTool = try context.tool(named: "codegen")
        let codegenExec = URL(fileURLWithPath: codegenTool.path.string)

        let arguments: [String] = [
            "Sources/C2TS",
            "--swift_out", "Sources/C2TS/Gen",
            "--ts_out", "src/Gen",
        ]

        let (stdout, stderr) = try RunProcess.run(exec: codegenExec, arguments: arguments)
        if !stdout.isEmpty {
            print(stdout)
        }
        if !stderr.isEmpty {
            Diagnostics.error(stderr)
        }
    }
}

enum RunProcess {
    static func run(exec: URL, arguments: [String]) throws -> (stdout: String, stderr: String) {
        var out = Data()
        func writeOut(_ data: Data) {
            out.append(data)
        }

        var err = Data()
        func writeError(_ data: Data) {
            err.append(data)
        }

        let queue = DispatchQueue(label: "runProcess")

        let outPipe = Pipe()
        outPipe.fileHandleForReading.readabilityHandler = { (h) in
            queue.sync {
                let d = h.availableData
                writeOut(d)
                if d.isEmpty {
                    outPipe.fileHandleForReading.readabilityHandler = nil
                }
            }
        }

        let errPipe = Pipe()
        errPipe.fileHandleForReading.readabilityHandler = { (h) in
            queue.sync {
                let d = h.availableData
                writeError(d)
                if d.isEmpty {
                    errPipe.fileHandleForReading.readabilityHandler = nil
                }
            }
        }

        let p = Process()
        p.executableURL = exec
        p.arguments = arguments
        p.standardOutput = outPipe
        p.standardError = errPipe
        try p.run()
        p.waitUntilExit()

        queue.sync {
            writeOut(outPipe.fileHandleForReading.availableData)
            writeError(errPipe.fileHandleForReading.availableData)
        }

        return (
            stdout: String(data: out, encoding: .utf8)?.trimmingCharacters(in: .newlines) ?? "",
            stderr: String(data: err, encoding: .utf8)?.trimmingCharacters(in: .newlines) ?? ""
        )
    }
}
