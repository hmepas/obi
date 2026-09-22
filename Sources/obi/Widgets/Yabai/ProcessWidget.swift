import AppKit

/// Windows of the focused space (any display) as app icons, preceded by the space layout badge
/// and the Hammerspoon mode badge read from the mode file.
final class ProcessWidget: Widget {
    private struct Mode: Decodable {
        let mode: String
        let color: String
    }

    private let theme: Theme
    private let stack = NSStackView()
    var view: NSView { stack }
    private var ctx: Context!
    private var sub: YabaiStore.Subscription?
    private var eventSub: Events.Subscription?
    private var mode = Mode(mode: "", color: "")
    private var watcher: DispatchSourceFileSystemObject?

    init(theme: Theme) {
        self.theme = theme
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = theme.metrics.gap
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isHidden = true
    }

    func start(_ ctx: Context) {
        self.ctx = ctx
        readMode()
        watchModeFile()
        sub = ctx.yabai.subscribe { [weak self] snap in self?.render(snap) }
        eventSub = ctx.events.on { [weak self] event in
            guard case .mode = event, let self else { return }
            self.readMode()
            self.render(ctx.yabai.snapshot)
        }
        render(ctx.yabai.snapshot)
    }

    func stop() {
        sub?.cancel()
        eventSub?.cancel()
        watcher?.cancel()
        watcher = nil
    }

    /// Hammerspoon rewrites the mode file in place; watching it means no HTTP ping is required
    /// (the dev instance on another port would otherwise never hear about mode changes).
    private func watchModeFile() {
        watcher?.cancel()
        let fd = open(ctx.config.modeFile, O_EVTONLY)
        guard fd >= 0 else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in self?.watchModeFile() }
            return
        }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: [.write, .extend, .delete, .rename], queue: .main)
        source.setEventHandler { [weak self, weak source] in
            guard let self, let source else { return }
            let flags = source.data
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in
                guard let self else { return }
                self.readMode()
                self.render(self.ctx.yabai.snapshot)
            }
            if flags.contains(.delete) || flags.contains(.rename) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in self?.watchModeFile() }
            }
        }
        source.setCancelHandler { close(fd) }
        source.resume()
        watcher = source
    }

    private func readMode() {
        guard let data = FileManager.default.contents(atPath: ctx.config.modeFile),
              let parsed = try? JSONDecoder().decode(Mode.self, from: data) else {
            mode = Mode(mode: "", color: "")
            return
        }
        mode = parsed
    }

    private func render(_ snap: Snapshot) {
        for v in stack.arrangedSubviews {
            stack.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        guard let space = snap.focusedSpace else {
            stack.isHidden = true
            return
        }

        let layout = PillView(theme: theme)
        layout.background = theme.roles.layoutBadgeBg
        _ = layout.addLabel(space.type, color: theme.roles.layoutBadgeText)
        stack.addArrangedSubview(layout)

        let modeName = mode.mode.trimmingCharacters(in: .whitespaces)
        if !modeName.isEmpty && modeName != "default" {
            let badge = PillView(theme: theme)
            badge.background = theme.palette.color(named: mode.color) ?? theme.roles.pillBg
            let label = badge.addLabel(modeName.uppercased(), color: theme.roles.badgeText)
            label.font = NSFontManager.shared.convert(theme.font, toHaveTrait: .italicFontMask)
            stack.addArrangedSubview(badge)
        }

        let excluded = ctx.config.appsExclude
        let windows = snap.windows
            .filter { $0.space == space.index && !$0.isMinimized && !$0.isPanel && !excluded.contains($0.app.lowercased()) }
            .sorted { a, b in
                if a.frame.x != b.frame.x { return a.frame.x < b.frame.x }
                if a.frame.y != b.frame.y { return a.frame.y < b.frame.y }
                if a.stackIndex != b.stackIndex { return a.stackIndex < b.stackIndex }
                return a.id < b.id
            }
        let symbols = ctx.config.appIcons
        for w in windows {
            let pill = PillView(theme: theme)
            pill.background = w.hasFocus ? theme.roles.focusedBg : theme.roles.pillBg
            pill.stack.addArrangedSubview(AppIcons.view(
                app: w.app, pid: w.pid, size: theme.metrics.iconSize,
                tint: w.hasFocus ? theme.roles.focusedText : theme.roles.pillText, symbols: symbols
            ))
            pill.onClick = { [weak self] _ in self?.ctx.yabai.client.focusWindow(id: w.id) }
            stack.addArrangedSubview(pill)
        }
        stack.isHidden = false
    }
}
