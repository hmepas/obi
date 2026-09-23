import AppKit

/// Rounded pill: a horizontal stack of arbitrary content on a colored background.
/// Handles click / right-click / hover callbacks.
class PillView: NSView {
    let stack = NSStackView()
    let theme: Theme
    var onClick: ((NSEvent) -> Void)?
    var onRightClick: ((NSEvent) -> Void)?
    var onHover: ((Bool) -> Void)?

    var background: NSColor { didSet { needsDisplay = true } }
    var ring: NSColor? { didSet { needsDisplay = true } }
    /// Ring drawn while the pointer is over the pill (simple-bar's hover-ring).
    var hoverRing: NSColor? { didSet { needsDisplay = true } }
    private var hovered = false { didSet { needsDisplay = true } }

    private var trackingArea: NSTrackingArea?
    private var pressed = false

    init(theme: Theme, paddingH: CGFloat? = nil) {
        self.theme = theme
        self.background = theme.roles.pillBg
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = theme.metrics.pillRadius
        layer?.masksToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = theme.metrics.iconGap
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.detachesHiddenViews = true
        addSubview(stack)
        let pad = paddingH ?? theme.metrics.pillPaddingH
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: theme.metrics.pillHeight),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: pad),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -pad),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        layer?.backgroundColor = background.cgColor
        let border = (hovered ? hoverRing : nil) ?? ring
        layer?.borderColor = border?.cgColor
        layer?.borderWidth = border == nil ? 0 : (hovered && hoverRing != nil ? 1.5 : 1)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea { removeTrackingArea(trackingArea) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self)
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        hovered = true
        onHover?(true)
    }

    override func mouseExited(with event: NSEvent) {
        hovered = false
        onHover?(false)
    }

    override func mouseDown(with event: NSEvent) { pressed = true }

    override func mouseUp(with event: NSEvent) {
        defer { pressed = false }
        guard pressed, bounds.contains(convert(event.locationInWindow, from: nil)) else { return }
        if event.modifierFlags.contains(.command) { return } // Cmd+click = middle click, no action
        onClick?(event)
    }

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?(event)
    }

    // MARK: - content helpers

    func addLabel(_ text: String, color: NSColor? = nil) -> NSTextField {
        let label = PillView.makeLabel(text, theme: theme, color: color ?? theme.roles.pillText)
        stack.addArrangedSubview(label)
        return label
    }

    func addSymbol(_ name: String, size: CGFloat? = nil, color: NSColor? = nil) -> NSImageView {
        let view = PillView.makeSymbol(name, size: size ?? theme.metrics.iconSize, color: color ?? theme.roles.pillText)
        stack.addArrangedSubview(view)
        return view
    }

    static func makeLabel(_ text: String, theme: Theme, color: NSColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = theme.font
        label.textColor = color
        label.lineBreakMode = .byClipping
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }

    static func symbolImage(_ name: String, size: CGFloat) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: size, weight: .regular))
    }

    static func makeSymbol(_ name: String, size: CGFloat, color: NSColor) -> NSImageView {
        let view = NSImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        // No scaling: every symbol renders at the same point size, so glyph weights match.
        view.imageScaling = .scaleNone
        view.contentTintColor = color
        view.image = symbolImage(name, size: size)
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: size + 4),
            view.heightAnchor.constraint(equalToConstant: size + 4),
        ])
        return view
    }
}

/// Pill with an optional leading SF Symbol and a text label — the shape every data widget uses.
final class DataPill: PillView {
    private let icon: NSImageView
    private let label: NSTextField

    override init(theme: Theme, paddingH: CGFloat? = nil) {
        icon = PillView.makeSymbol("circle", size: theme.metrics.iconSize, color: theme.roles.dataIcon)
        label = PillView.makeLabel("", theme: theme, color: theme.roles.dataText)
        super.init(theme: theme, paddingH: paddingH)
        icon.isHidden = true
        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(label)
    }

    required init?(coder: NSCoder) { fatalError() }

    var text: String {
        get { label.stringValue }
        set { label.stringValue = newValue }
    }

    var textColor: NSColor {
        get { label.textColor ?? theme.roles.dataText }
        set { label.textColor = newValue }
    }

    func setSymbol(_ name: String?) {
        guard let name else { icon.isHidden = true; return }
        icon.image = PillView.symbolImage(name, size: theme.metrics.iconSize)
        icon.isHidden = false
    }

    var symbolColor: NSColor? {
        get { icon.contentTintColor }
        set { icon.contentTintColor = newValue }
    }
}
