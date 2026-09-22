import Foundation

/// launchd agent management: `obi install` / `obi uninstall`. Both are idempotent.
enum Install {
    static let label = "com.hmepas.obi"
    static var plistPath: String { ("~/Library/LaunchAgents/\(label).plist" as NSString).expandingTildeInPath }
    static var domain: String { "gui/\(getuid())" }

    static func install() -> Int32 {
        let binary = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath().path
        let absolute = binary.hasPrefix("/") ? binary
            : FileManager.default.currentDirectoryPath + "/" + binary
        let log = ("~/Library/Logs/obi.log" as NSString).expandingTildeInPath
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key><string>\(label)</string>
            <key>ProgramArguments</key><array><string>\(absolute)</string></array>
            <key>RunAtLoad</key><true/>
            <key>KeepAlive</key><true/>
            <key>ProcessType</key><string>Interactive</string>
            <key>StandardOutPath</key><string>\(log)</string>
            <key>StandardErrorPath</key><string>\(log)</string>
        </dict>
        </plist>
        """
        _ = launchctl(["bootout", "\(domain)/\(label)"])
        do {
            try FileManager.default.createDirectory(atPath: (plistPath as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
            try plist.write(toFile: plistPath, atomically: true, encoding: .utf8)
        } catch {
            FileHandle.standardError.write("obi: cannot write \(plistPath): \(error)\n".data(using: .utf8)!)
            return 1
        }
        let status = launchctl(["bootstrap", domain, plistPath])
        print(status == 0 ? "installed \(label) → \(absolute)" : "launchctl bootstrap failed (\(status))")
        return status
    }

    static func uninstall() -> Int32 {
        _ = launchctl(["bootout", "\(domain)/\(label)"])
        try? FileManager.default.removeItem(atPath: plistPath)
        print("uninstalled \(label)")
        return 0
    }

    private static func launchctl(_ args: [String]) -> Int32 {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        p.arguments = args
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        do { try p.run() } catch { return 1 }
        p.waitUntilExit()
        return p.terminationStatus
    }
}
