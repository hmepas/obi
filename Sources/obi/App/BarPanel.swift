import AppKit

/// Borderless, transparent, non-activating panel pinned to the top of the main display.
final class BarPanel: NSPanel {
    var height: CGFloat
    private let offset: CGFloat

    init(height: CGFloat, offset: CGFloat) {
        self.height = height
        self.offset = offset
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        // Above the menu bar: since macOS 27.2 MenuBarAgent keeps a transparent window one level
        // above the (hidden) menu bar across the whole strip, and a click reaching it unhides the
        // menu bar. Below that level every click on a pill pulled the system menu bar down.
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2)
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
    /// Below the menu-bar level AppKit would push the frame out of the menu bar strip.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
    override var canBecomeMain: Bool { false }

    /// Main display = the one carrying the (hidden) system menu bar.
    func place() {
        guard let screen = NSScreen.screens.first else { return }
        let f = screen.frame
        setFrame(NSRect(x: f.minX, y: f.maxY - height - offset, width: f.width, height: height), display: true)
    }
}
