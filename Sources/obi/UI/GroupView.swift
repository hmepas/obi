import AppKit

/// Rounded container holding a row of pills, optionally split by vertical hairlines.
/// Hides itself when every child is hidden.
final class GroupView: NSView {
    let stack = NSStackView()
    private var observers: [NSKeyValueObservation] = []
    private var children: [NSView] = []
    private var separators: [NSView] = []   // separators[i] sits before children[i + 1]
    private let theme: Theme
    private let separatorColor: NSColor?

    init(theme: Theme, background: NSColor, separator: NSColor? = nil) {
        self.theme = theme
        self.separatorColor = separator
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = theme.metrics.groupRadius
        layer?.backgroundColor = background.cgColor
        translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = theme.metrics.gap
        stack.detachesHiddenViews = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: theme.metrics.groupHeight),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: theme.metrics.groupPaddingH),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -theme.metrics.groupPaddingH),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func setChildren(_ views: [NSView]) {
        observers.removeAll()
        for v in stack.arrangedSubviews {
            stack.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        children = views
        separators.removeAll()
        for (i, v) in views.enumerated() {
            if i > 0, let color = separatorColor {
                let sep = GroupView.hairline(color: color, height: theme.metrics.pillHeight - 6)
                separators.append(sep)
                stack.addArrangedSubview(sep)
            }
            stack.addArrangedSubview(v)
            observers.append(v.observe(\.isHidden) { [weak self] _, _ in self?.updateVisibility() })
        }
        updateVisibility()
    }

    private func updateVisibility() {
        var seenVisible = false
        for (i, v) in children.enumerated() {
            if i > 0, i - 1 < separators.count {
                let hidden = v.isHidden || !seenVisible
                if separators[i - 1].isHidden != hidden { separators[i - 1].isHidden = hidden }
            }
            if !v.isHidden { seenVisible = true }
        }
        if isHidden == seenVisible { isHidden = !seenVisible }
    }

    static func hairline(color: NSColor, height: CGFloat) -> NSView {
        let line = NSView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.wantsLayer = true
        line.layer?.backgroundColor = color.cgColor
        NSLayoutConstraint.activate([
            line.widthAnchor.constraint(equalToConstant: 1),
            line.heightAnchor.constraint(equalToConstant: height),
        ])
        return line
    }
}
