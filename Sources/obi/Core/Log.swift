import Foundation

/// Appends timestamped lines to ~/Library/Logs/obi.log and mirrors them to stderr.
final class Log {
    private let handle: FileHandle?
    private let queue = DispatchQueue(label: "obi.log")
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    init(path: String = "~/Library/Logs/obi.log") {
        let expanded = (path as NSString).expandingTildeInPath
        if !FileManager.default.fileExists(atPath: expanded) {
            FileManager.default.createFile(atPath: expanded, contents: nil)
        }
        handle = FileHandle(forWritingAtPath: expanded)
        handle?.seekToEndOfFile()
    }

    func info(_ message: String) { write("INFO", message) }
    func error(_ message: String) { write("ERROR", message) }

    private func write(_ level: String, _ message: String) {
        let line = "\(formatter.string(from: Date())) [\(level)] \(message)\n"
        queue.async { [handle] in
            FileHandle.standardError.write(line.data(using: .utf8)!)
            handle?.write(line.data(using: .utf8)!)
        }
    }
}
