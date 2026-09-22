import Foundation

/// Parsed `~/.config/obi/config.toml` plus CLI overrides. Widgets read their own section
/// via `section("widgets.<name>")`; the core only knows the top-level keys.
struct Config {
    static let defaultPath = "~/.config/obi/config.toml"

    struct Section {
        let prefix: String
        let values: [String: TOMLValue]

        private func get(_ key: String) -> TOMLValue? { values[prefix.isEmpty ? key : "\(prefix).\(key)"] }

        func string(_ key: String, _ fallback: String) -> String {
            if case .string(let s)? = get(key) { return s }
            return fallback
        }
        func int(_ key: String, _ fallback: Int) -> Int {
            if case .int(let i)? = get(key) { return i }
            return fallback
        }
        func bool(_ key: String, _ fallback: Bool) -> Bool {
            if case .bool(let b)? = get(key) { return b }
            return fallback
        }
        /// Every `key = "string"` directly under this section.
        var stringEntries: [String: String] {
            var out: [String: String] = [:]
            let p = prefix.isEmpty ? "" : prefix + "."
            for (k, v) in values where k.hasPrefix(p) {
                let rest = k.dropFirst(p.count)
                if rest.contains("."), !prefix.isEmpty { continue }
                if case .string(let s) = v { out[String(rest)] = s }
            }
            return out
        }
        func strings(_ key: String, _ fallback: [String]) -> [String] {
            if case .array(let items)? = get(key) {
                return items.compactMap { if case .string(let s) = $0 { return s } else { return nil } }
            }
            return fallback
        }
    }

    let values: [String: TOMLValue]
    let path: String
    var portOverride: Int?
    var offset: CGFloat = 0

    init(values: [String: TOMLValue] = [:], path: String = Config.defaultPath) {
        self.values = values
        self.path = path
    }

    static func load(path: String?, log: Log?) -> Config {
        let p = ((path ?? defaultPath) as NSString).expandingTildeInPath
        guard let text = try? String(contentsOfFile: p, encoding: .utf8) else {
            log?.info("config: \(p) not found, using defaults")
            return Config(path: p)
        }
        do {
            let values = try TOML.parse(text)
            log?.info("config: loaded \(p) (\(values.count) keys)")
            return Config(values: values, path: p)
        } catch {
            log?.error("config: \(p): \(error), using defaults")
            return Config(path: p)
        }
    }

    func section(_ prefix: String) -> Section { Section(prefix: prefix, values: values) }
    private var root: Section { section("") }

    var theme: String { root.string("theme", "material-ocean") }
    var yabaiPath: String { root.string("yabai", "/opt/homebrew/bin/yabai") }
    var port: Int { portOverride ?? root.int("port", 7776) }
    var modeFile: String {
        (root.string("mode_file", "~/Library/Caches/uebersicht-simple-bar-index/yabai-mode") as NSString).expandingTildeInPath
    }
    var spacesExclude: [String] { section("spaces").strings("exclude", []) }
    /// Lowercased: app names are matched case-insensitively ("ghostty" hides "Ghostty").
    /// `[icons]`: app name (case-insensitive) → SF Symbol drawn instead of the app icon.
    var appIcons: [String: String] {
        Dictionary(section("icons").stringEntries.map { ($0.key.lowercased(), $0.value) }, uniquingKeysWith: { a, _ in a })
    }
    var appsExclude: Set<String> { Set(section("spaces").strings("apps_exclude", []).map { $0.lowercased() }) }
}
