import AppKit

/// Owns the panel, HTTP server and the current set of widgets. Reload / theme change
/// tears every widget down and builds a fresh Context.
final class Runtime {
    struct Options {
        var configPath: String?
        var port: Int?
        var offset: CGFloat = 0
    }

    let log = Log()
    private let options: Options
    private let events = Events()
    private let scheduler = Scheduler()
    private let shell: Shell
    private let layout = BarLayout()
    private var config: Config
    private var theme: Theme
    private var yabai: YabaiStore?
    private var panel: BarPanel?
    private var server: HTTPServer?
    private var widgets: [Widget] = []
    private var eventSub: Events.Subscription?
    private var sighup: DispatchSourceSignal?
    private var modeObserver: Any?

    init(options: Options) {
        self.options = options
        shell = Shell(log: log)
        config = Config.load(path: options.configPath, log: log)
        config.portOverride = options.port
        config.offset = options.offset
        theme = ThemeRegistry.get(config.theme) ?? ThemeRegistry.get(ThemeRegistry.defaultName)!
    }

    func start() {
        log.info("obi starting, pid \(ProcessInfo.processInfo.processIdentifier)")
        let panel = BarPanel(height: theme.metrics.barHeight, offset: config.offset)
        panel.contentView = layout.root
        panel.place()
        panel.orderFrontRegardless()
        self.panel = panel
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.panel?.place()
            self?.yabai?.refresh(.displays)
        }

        eventSub = events.on { [weak self] event in self?.handle(event) }
        startServer()
        installSighup()
        rebuild()
    }

    // MARK: - lifecycle

    private func rebuild() {
        widgets.forEach { $0.stop() }
        widgets.removeAll()

        if let panel {
            panel.height = theme.metrics.barHeight
            panel.backgroundColor = theme.roles.barBg
            panel.place()
        }

        let client = YabaiClient(path: config.yabaiPath, shell: shell, log: log)
        let store = YabaiStore(client: client)
        yabai = store
        let ctx = Context(config: config, theme: theme, yabai: store, scheduler: scheduler, shell: shell, events: events, log: log)
        let slots = WidgetRegistry.make(ctx)
        layout.set(slots, theme: theme)
        widgets = slots.all
        widgets.forEach { $0.start(ctx) }
        store.refreshAll()
        log.info("widgets built: \(widgets.count), theme \(theme.name)")
    }

    func reload() {
        var fresh = Config.load(path: options.configPath, log: log)
        fresh.portOverride = options.port
        fresh.offset = options.offset
        config = fresh
        if let t = ThemeRegistry.get(config.theme) { theme = t }
        rebuild()
    }

    func setTheme(_ name: String) -> Bool {
        guard let t = ThemeRegistry.get(name) else { return false }
        theme = t
        rebuild()
        return true
    }

    private func handle(_ event: Event) {
        switch event {
        case .refresh(let kind): yabai?.refresh(kind)
        case .reload: reload()
        case .theme(let name):
            if !setTheme(name) { log.error("theme: unknown '\(name)'") }
        case .mode: break // ProcessWidget subscribes directly
        }
    }

    private func startServer() {
        do {
            let server = try HTTPServer(port: UInt16(config.port), log: log) { [events] path in
                switch path {
                case "/health": return (200, "ok")
                case "/yabai/spaces/refresh": events.emit(.refresh(.spaces)); return (200, "ok")
                case "/yabai/windows/refresh": events.emit(.refresh(.windows)); return (200, "ok")
                case "/yabai/displays/refresh": events.emit(.refresh(.displays)); return (200, "ok")
                case "/skhd/mode/refresh": events.emit(.mode); return (200, "ok")
                case "/config/reload": events.emit(.reload); return (200, "ok")
                default:
                    if path.hasPrefix("/theme/") {
                        let name = String(path.dropFirst("/theme/".count))
                        guard ThemeRegistry.get(name) != nil else { return (404, "unknown theme \(name)") }
                        events.emit(.theme(name))
                        return (200, "ok")
                    }
                    return (404, "not found")
                }
            }
            server.start()
            self.server = server
        } catch {
            log.error("http: cannot listen on \(config.port): \(error)")
        }
    }

    private func installSighup() {
        signal(SIGHUP, SIG_IGN)
        let source = DispatchSource.makeSignalSource(signal: SIGHUP, queue: .main)
        source.setEventHandler { [weak self] in
            self?.log.info("SIGHUP: reloading")
            self?.reload()
        }
        source.resume()
        sighup = source
    }
}
