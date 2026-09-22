import AppKit

/// App icons by pid, cached. Falls back to a generic app icon.
enum AppIcons {
    private static var cache: [pid_t: NSImage] = [:]

    static func icon(pid: pid_t) -> NSImage {
        if let cached = cache[pid] { return cached }
        let image = NSRunningApplication(processIdentifier: pid)?.icon
            ?? NSWorkspace.shared.icon(for: .applicationBundle)
        if cache.count > 256 { cache.removeAll() }
        cache[pid] = image
        return image
    }

    /// Resolves an `[icons]` value: `svg:<builtin name>`, `svg:<path.svg>` (template image),
    /// or an SF Symbol name. Result is monochrome and takes the view's tint.
    static func glyph(_ spec: String, size: CGFloat) -> NSImage? {
        if spec.hasPrefix("svg:") {
            let ref = String(spec.dropFirst(4))
            let data: Data?
            if let builtin = BuiltinIcons.all[ref] {
                data = builtin.data(using: .utf8)
            } else {
                data = FileManager.default.contents(atPath: (ref as NSString).expandingTildeInPath)
            }
            guard let data, let image = NSImage(data: data) else { return nil }
            image.size = NSSize(width: size, height: size)
            image.isTemplate = true
            return image
        }
        return PillView.symbolImage(spec, size: size)
    }

    /// App icon, or the configured glyph (monochrome, tinted) when `symbols` has an entry for the app.
    static func view(app: String, pid: pid_t, size: CGFloat, tint: NSColor, alpha: CGFloat = 1, symbols: [String: String]) -> NSImageView {
        let view: NSImageView
        if let spec = symbols[app.lowercased()], let image = glyph(spec, size: size) {
            view = NSImageView(image: image)
            view.imageScaling = .scaleNone
            view.contentTintColor = tint
        } else {
            view = NSImageView(image: icon(pid: pid))
            view.imageScaling = .scaleProportionallyUpOrDown
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alphaValue = alpha
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: size),
            view.heightAnchor.constraint(equalToConstant: size),
        ])
        return view
    }
}
