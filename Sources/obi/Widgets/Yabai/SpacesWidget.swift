import AppKit

/// All spaces of all displays as pills: label (or index) + one icon per app with windows there.
/// Click focuses the space, Alt+click renames its label inline.
final class SpacesWidget: Widget {
    private let theme: Theme
    private let stack = NSStackView()
    var view: NSView { stack }
    private var ctx: Context!
    private var sub: YabaiStore.Subscription?

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
        sub = ctx.yabai.subscribe { [weak self] snap in self?.render(snap) }
        render(ctx.yabai.snapshot)
    }

    func stop() {
        sub?.cancel()
        sub = nil
    }

    private func render(_ snap: Snapshot) {
        for v in stack.arrangedSubviews {
            stack.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        let excluded = Set(ctx.config.spacesExclude)
        let appsExcluded = ctx.config.appsExclude

        var displayIndexes = snap.displays.map(\.index).sorted()
        if displayIndexes.isEmpty { displayIndexes = Array(Set(snap.spaces.map(\.display))).sorted() }

        var first = true
        for display in displayIndexes {
            let spaces = snap.spaces.filter { $0.display == display && !excluded.contains($0.label) }
            if spaces.isEmpty { continue }
            if !first { stack.addArrangedSubview(makeSeparator()) }
            first = false
            // Sticky windows show in every space of their display; an invisible sticky window
            // is a hidden overlay (e.g. a quick terminal), not something on the space.
            let sticky = snap.windows.filter { $0.isSticky && $0.display == display && $0.isVisible && !$0.isMinimized }
            for space in spaces {
                // Match by window.space rather than space.windows: the windows query refreshes on
                // window events, the spaces query only on space events, so its list goes stale.
                var list = snap.windows.filter { $0.space == space.index && !$0.isSticky }
                list.append(contentsOf: sticky)
                stack.addArrangedSubview(makePill(space, windows: list, appsExcluded: appsExcluded))
            }
        }
        stack.isHidden = stack.arrangedSubviews.isEmpty
    }

    private func makePill(_ space: Space, windows: [Window], appsExcluded: Set<String>) -> PillView {
        let pill = PillView(theme: theme, paddingH: theme.metrics.spacePaddingH)
        pill.stack.spacing = theme.metrics.spaceIconGap
        let labelText = space.label.isEmpty ? String(space.index) : space.label

        let textColor: NSColor
        if space.isNativeFullscreen {
            pill.background = theme.roles.fullscreenBg
            textColor = theme.roles.focusedText
        } else if space.hasFocus {
            pill.background = theme.roles.focusedBg
            textColor = theme.roles.focusedText
        } else {
            pill.background = theme.roles.pillBg
            textColor = theme.roles.pillText
            if space.isVisible { pill.ring = theme.roles.visibleRing }
            pill.hoverRing = theme.roles.hoverRing
        }
        let label = pill.addLabel(labelText, color: textColor)

        let visible = windows
            .filter { !$0.isMinimized && !$0.isPanel && !appsExcluded.contains($0.app.lowercased()) }
            .sorted { a, b in
                if a.frame.x != b.frame.x { return a.frame.x < b.frame.x }
                if a.frame.y != b.frame.y { return a.frame.y < b.frame.y }
                if a.stackIndex != b.stackIndex { return a.stackIndex < b.stackIndex }
                return a.id < b.id
            }
        var seen = Set<String>()
        let symbols = ctx.config.appIcons
        for w in visible where seen.insert(w.app).inserted {
            let focused = visible.contains { $0.app == w.app && $0.hasFocus }
            pill.stack.addArrangedSubview(AppIcons.view(
                app: w.app, pid: w.pid, size: theme.metrics.spaceIconSize, tint: textColor,
                alpha: focused ? 1 : 0.5, symbols: symbols
            ))
        }

        pill.onClick = { [weak self, weak pill] event in
            guard let self, let pill else { return }
            if event.modifierFlags.contains(.option) {
                InlineEditor.present(over: pill, text: space.label, theme: self.theme) { [weak self] text in
                    self?.ctx.yabai.client.label(spaceIndex: space.index, text)
                    self?.ctx.yabai.refresh(.spaces)
                }
                _ = label
            } else if !space.hasFocus {
                self.ctx.yabai.client.focusSpace(index: space.index)
            }
        }
        return pill
    }

    private func makeSeparator() -> NSView {
        let dot = NSView()
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.wantsLayer = true
        dot.layer?.backgroundColor = theme.roles.separator.cgColor
        dot.layer?.cornerRadius = 2.5
        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 5),
            dot.heightAnchor.constraint(equalToConstant: 5),
        ])
        return dot
    }
}
