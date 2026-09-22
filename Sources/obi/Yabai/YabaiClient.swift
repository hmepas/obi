import Foundation

/// Serialized access to the yabai binary. Queries decode JSON; completions land on main.
final class YabaiClient {
    let path: String
    private let shell: Shell
    private let log: Log
    private let queue = DispatchQueue(label: "obi.yabai", qos: .userInitiated)

    init(path: String, shell: Shell, log: Log) {
        self.path = path
        self.shell = shell
        self.log = log
    }

    func query<T: Decodable>(_ kind: YabaiKind, as type: T.Type, completion: @escaping (T?) -> Void) {
        queue.async {
            let out = self.shell.run(self.path, ["-m", "query", "--\(kind.rawValue)"])
            var result: T?
            if out.ok, let data = out.stdout.data(using: .utf8) {
                do { result = try JSONDecoder().decode(T.self, from: data) }
                catch { self.log.error("yabai: decode \(kind): \(error)") }
            } else {
                self.log.error("yabai: query --\(kind.rawValue) failed: \(out.stderr.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
            DispatchQueue.main.async { completion(result) }
        }
    }

    func focusSpace(index: Int) { command(["-m", "space", "--focus", "\(index)"]) }
    func label(spaceIndex: Int, _ label: String) { command(["-m", "space", "\(spaceIndex)", "--label", label]) }
    func focusWindow(id: Int) { command(["-m", "window", "--focus", "\(id)"]) }

    private func command(_ args: [String]) {
        queue.async {
            let out = self.shell.run(self.path, args)
            if !out.ok {
                self.log.error("yabai: \(args.joined(separator: " ")): \(out.stderr.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
        }
    }
}
