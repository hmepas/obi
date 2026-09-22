import AppKit

/// Dark rounded container holding a row of pills. Hides itself when every child is hidden.
final class GroupView: NSView {
    let stack = NSStackView()
    private var observers: [NSKeyValueObservation] = []
    private let leadingPad: CGFloat

    init(theme: Theme, leadingPad: CGFloat? = nil) {
        self.leadingPad = leadingPad ?? theme.metrics.groupPaddingH
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = theme.metrics.groupRadius
        layer?.backgroundColor = theme.roles.groupBg.cgColor
        translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = theme.metrics.gap
        stack.detachesHiddenViews = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: theme.metrics.groupHeight),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: self.leadingPad),
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
        for v in views {
            stack.addArrangedSubview(v)
            observers.append(v.observe(\.isHidden) { [weak self] _, _ in self?.updateVisibility() })
        }
        updateVisibility()
    }

    private func updateVisibility() {
        let anyVisible = stack.arrangedSubviews.contains { !$0.isHidden }
        if isHidden == anyVisible { isHidden = !anyVisible }
    }
}
