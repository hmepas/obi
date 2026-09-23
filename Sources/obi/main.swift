import AppKit

let usage = """
usage:
  obi [--port N] [--offset PX] [--config PATH]   run the bar + HTTP server
  obi install | uninstall                        manage the launchd agent
  obi reload                                     GET /config/reload
  obi theme                                      list available themes
  obi theme <name>                               GET /theme/<name>
  obi refresh spaces|windows|displays|mode       GET the matching refresh endpoint
"""

func option(_ name: String, in args: [String]) -> String? {
    guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
    return args[i + 1]
}

let args = Array(CommandLine.arguments.dropFirst())
let configPath = option("--config", in: args)
let portArg = option("--port", in: args).flatMap(Int.init)

func clientPort() -> Int {
    var cfg = Config.load(path: configPath, log: nil)
    cfg.portOverride = portArg
    return cfg.port
}

switch args.first {
case "install":
    exit(Install.install())
case "uninstall":
    exit(Install.uninstall())
case "reload":
    exit(Client.get("/config/reload", port: clientPort()))
case "theme":
    guard args.count >= 2 else {
        for name in ThemeRegistry.all.keys.sorted() { print(name) }
        exit(0)
    }
    exit(Client.get("/theme/\(args[1])", port: clientPort()))
case "refresh":
    guard args.count >= 2 else { print(usage); exit(2) }
    let path: String
    switch args[1] {
    case "spaces", "windows", "displays": path = "/yabai/\(args[1])/refresh"
    case "mode": path = "/skhd/mode/refresh"
    default: print(usage); exit(2)
    }
    exit(Client.get(path, port: clientPort()))
case "-h", "--help", "help":
    print(usage)
    exit(0)
case .some(let cmd) where !cmd.hasPrefix("--"):
    print("unknown command: \(cmd)\n\(usage)")
    exit(2)
default:
    let options = Runtime.Options(
        configPath: configPath,
        port: portArg,
        offset: option("--offset", in: args).flatMap(Double.init).map { CGFloat($0) } ?? 0
    )
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let delegate = AppDelegate(options: options)
    app.delegate = delegate
    app.run()
}
