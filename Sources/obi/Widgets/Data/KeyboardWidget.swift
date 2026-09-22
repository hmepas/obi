import AppKit
import Carbon

/// Current input source name, truncated. Updated from the TIS change notification, no polling.
final class KeyboardWidget: Widget {
    private let pill: DataPill
    var view: NSView { pill }
    private var ctx: Context!
    private var maxLength = 3
    private var observer: NSObjectProtocol?

    init(theme: Theme) {
        pill = DataPill(theme: theme)
    }

    func start(_ ctx: Context) {
        self.ctx = ctx
        maxLength = ctx.config.section("widgets.keyboard").int("max_length", 3)
        let name = Notification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String)
        observer = DistributedNotificationCenter.default().addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            // TIS may lag the notification by a moment.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { self?.render() }
        }
        render()
    }

    func stop() {
        if let observer { DistributedNotificationCenter.default().removeObserver(observer) }
        observer = nil
    }

    private func render() {
        let name = Self.currentName()
        pill.text = String(name.prefix(maxLength))
        pill.isHidden = name.isEmpty
    }

    static func currentName() -> String {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let ptr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) else { return "" }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }
}
