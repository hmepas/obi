import Foundation

/// Runs external processes with a timeout. `run` blocks and is meant for background queues;
/// `runAsync` runs on a utility queue and delivers the result on main.
final class Shell {
    struct Output {
        let stdout: String
        let stderr: String
        let status: Int32
        var ok: Bool { status == 0 }
    }

    private let log: Log
    private let queue = DispatchQueue(label: "obi.shell", qos: .utility, attributes: .concurrent)

    init(log: Log) { self.log = log }

    func run(_ path: String, _ args: [String] = [], timeout: TimeInterval = 5) -> Output {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: path)
        proc.arguments = args
        let out = Pipe(), err = Pipe()
        proc.standardOutput = out
        proc.standardError = err
        proc.standardInput = FileHandle.nullDevice
        do {
            try proc.run()
        } catch {
            log.error("shell: \(path) \(args.joined(separator: " ")): \(error)")
            return Output(stdout: "", stderr: "\(error)", status: -1)
        }
        let killer = DispatchWorkItem { [log] in
            if proc.isRunning {
                log.error("shell: \(path) timed out after \(timeout)s, killing")
                proc.terminate()
            }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: killer)
        // Drain stderr concurrently so a chatty process cannot deadlock on a full pipe.
        var errData = Data()
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global().async {
            errData = err.fileHandleForReading.readDataToEndOfFile()
            group.leave()
        }
        let outData = out.fileHandleForReading.readDataToEndOfFile()
        proc.waitUntilExit()
        group.wait()
        killer.cancel()
        return Output(
            stdout: String(decoding: outData, as: UTF8.self),
            stderr: String(decoding: errData, as: UTF8.self),
            status: proc.terminationStatus
        )
    }

    func runAsync(_ path: String, _ args: [String] = [], timeout: TimeInterval = 5, completion: ((Output) -> Void)? = nil) {
        queue.async {
            let result = self.run(path, args, timeout: timeout)
            if let completion { DispatchQueue.main.async { completion(result) } }
        }
    }

    func osascript(_ script: String, timeout: TimeInterval = 5) -> Output {
        run("/usr/bin/osascript", ["-e", script], timeout: timeout)
    }

    func open(app: String) { runAsync("/usr/bin/open", ["-a", app]) }
    func open(url: String) { runAsync("/usr/bin/open", [url]) }
}
