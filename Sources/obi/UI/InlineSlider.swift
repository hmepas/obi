import AppKit

/// 0–100 slider that lives inside a pill and unfolds to the right while the pointer hovers the
/// pill (simple-bar's mic/sound behaviour): dark track, round knob, knob grows on hover.
final class InlineSlider: NSView {
    var onChange: ((Int) -> Void)?

    private let theme: Theme
    private let fullWidth: CGFloat = 100
    private let trackHeight: CGFloat = 10
    private var widthConstraint: NSLayoutConstraint!
    private var value: Int = 0
    private var dragging = false
    private var hoveredPill = false
    private var hoveredKnob = false { didSet { needsDisplay = true } }
    private var trackingArea: NSTrackingArea?

    init(theme: Theme) {
        self.theme = theme
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.masksToBounds = true
        alphaValue = 0.7
        widthConstraint = widthAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([widthConstraint, heightAnchor.constraint(equalToConstant: theme.metrics.pillHeight)])
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Adds the slider to the pill and wires hover → unfold.
    func attach(to pill: PillView) {
        pill.stack.addArrangedSubview(self)
        pill.onHover = { [weak self] inside in
            guard let self else { return }
            self.hoveredPill = inside
            if inside { self.setExpanded(true) } else if !self.dragging { self.setExpanded(false) }
        }
    }

    func setValue(_ v: Int) {
        guard !dragging else { return }
        value = max(0, min(100, v))
        needsDisplay = true
    }

    private func setExpanded(_ expanded: Bool) {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.32
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0, 0.2, 1)
            ctx.allowsImplicitAnimation = true
            widthConstraint.constant = expanded ? fullWidth : 0
            window?.contentView?.layoutSubtreeIfNeeded()
        }
    }

    // MARK: - drawing

    private var trackRect: NSRect {
        NSRect(x: 0, y: (bounds.height - trackHeight) / 2, width: fullWidth, height: trackHeight)
    }

    private var knobCenterX: CGFloat {
        trackHeight / 2 + (fullWidth - trackHeight) * CGFloat(value) / 100
    }

    override func draw(_ dirtyRect: NSRect) {
        theme.roles.sliderTrack.setFill()
        NSBezierPath(roundedRect: trackRect, xRadius: trackHeight / 2, yRadius: trackHeight / 2).fill()
        let scale: CGFloat = hoveredKnob || dragging ? 1.5 : 1
        let d = trackHeight * scale
        let knob = NSRect(x: knobCenterX - d / 2, y: (bounds.height - d) / 2, width: d, height: d)
        theme.roles.text.setFill()
        NSBezierPath(ovalIn: knob).fill()
    }

    // MARK: - mouse

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea { removeTrackingArea(trackingArea) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect], owner: self)
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) { alphaValue = 1 }
    override func mouseExited(with event: NSEvent) {
        hoveredKnob = false
        if !dragging { alphaValue = 0.7 }
    }

    override func mouseMoved(with event: NSEvent) {
        let x = convert(event.locationInWindow, from: nil).x
        hoveredKnob = abs(x - knobCenterX) <= trackHeight
    }

    override func mouseDown(with event: NSEvent) {
        dragging = true
        apply(event)
    }

    override func mouseDragged(with event: NSEvent) { apply(event) }

    override func mouseUp(with event: NSEvent) {
        dragging = false
        needsDisplay = true
        if !hoveredPill { setExpanded(false) }
    }

    private func apply(_ event: NSEvent) {
        let x = convert(event.locationInWindow, from: nil).x
        let ratio = (x - trackHeight / 2) / (fullWidth - trackHeight)
        let v = Int((max(0, min(1, ratio)) * 100).rounded())
        guard v != value else { return }
        value = v
        needsDisplay = true
        onChange?(v)
    }
}
