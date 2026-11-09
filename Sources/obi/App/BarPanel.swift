import AppKit

/// Borderless, transparent, non-activating panel pinned to the top of the main display.
final class BarPanel: NSPanel {
    var height: CGFloat
    private let offset: CGFloat

    init(height: CGFloat, offset: CGFloat) {
        self.height = height
        self.offset = offset
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        level = Self.aboveMenuBar
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

    /// Since macOS 27.2 MenuBarAgent keeps a transparent window one level above the (hidden)
    /// menu bar across the whole strip, and a click reaching it slides the menu bar out. The bar
    /// normally sits above that window so clicks stay on the pills; while the system menu bar is
    /// shown (pointer at the top edge) it drops below it so the menu bar stays usable.
    private static let aboveMenuBar = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2)
    private static let belowMenuBar = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) - 1)
    private var menuBarTimer: Timer?

    func trackSystemMenuBar() {
        menuBarTimer?.invalidate()
        menuBarTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self, let screen = NSScreen.screens.first else { return }
            let pointerInStrip = NSEvent.mouseLocation.y >= screen.frame.maxY - 40
            guard pointerInStrip || self.level == Self.belowMenuBar else { return }
            let shown = Self.systemMenuBarShown()
            let wanted = shown ? Self.belowMenuBar : Self.aboveMenuBar
            if self.level != wanted { self.level = wanted }
        }
    }

    private static func systemMenuBarShown() -> Bool {
        guard let list = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else { return false }
        return list.contains { $0[kCGWindowName as String] as? String == "Menubar" && $0[kCGWindowOwnerName as String] as? String == "Window Server" }
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
