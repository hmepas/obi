import AppKit

/// Text field laid over a pill for renaming a space. Enter commits, Esc / focus loss cancels.
final class InlineEditor: NSTextField, NSTextFieldDelegate {
    private var onCommit: ((String) -> Void)?
    private var finished = false

    static func present(over view: NSView, text: String, theme: Theme, onCommit: @escaping (String) -> Void) {
        guard let parent = view.superview, let window = view.window else { return }
        let editor = InlineEditor(frame: view.frame.insetBy(dx: 0, dy: 0))
        editor.onCommit = onCommit
        editor.stringValue = text
        editor.font = theme.font
        editor.textColor = theme.roles.focusedText
        editor.backgroundColor = theme.roles.focusedBg
        editor.isBezeled = false
        editor.isBordered = false
        editor.focusRingType = .none
        editor.alignment = .center
        editor.delegate = editor
        editor.wantsLayer = true
        editor.layer?.cornerRadius = theme.metrics.pillRadius
        editor.layer?.masksToBounds = true
        parent.addSubview(editor, positioned: .above, relativeTo: view)
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(editor)
        editor.currentEditor()?.selectAll(nil)
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        switch selector {
        case #selector(NSResponder.insertNewline(_:)):
            finish(commit: true)
            return true
        case #selector(NSResponder.cancelOperation(_:)):
            finish(commit: false)
            return true
        default:
            return false
        }
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        finish(commit: false)
    }

    private func finish(commit: Bool) {
        guard !finished else { return }
        finished = true
        let value = stringValue.trimmingCharacters(in: .whitespaces)
        window?.makeFirstResponder(nil)
        removeFromSuperview()
        window?.resignKey()
        if commit { onCommit?(value) }
    }
}
