import AppKit

/// Borderless, transparent, non-activating panel pinned to the top of the main display.
final class BarPanel: NSPanel {
    private let height: CGFloat
    private let offset: CGFloat

    init(height: CGFloat, offset: CGFloat) {
        self.height = height
        self.offset = offset
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = false
        hidesOnDeactivate = false
        isMovable = false
        isMovableByWindowBackground = false
        becomesKeyOnlyIfNeeded = true
        isReleasedWhenClosed = false
        animationBehavior = .none
        titleVisibility = .hidden
        appearance = NSAppearance(named: .darkAqua)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Main display = the one carrying the (hidden) system menu bar.
    func place() {
        guard let screen = NSScreen.screens.first else { return }
        let f = screen.frame
        setFrame(NSRect(x: f.minX, y: f.maxY - height - offset, width: f.width, height: height), display: true)
    }
}
