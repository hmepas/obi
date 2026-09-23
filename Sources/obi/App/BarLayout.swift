import AppKit

/// Bar content: [spaces group][process group] … [data group]. Groups hide when empty.
final class BarLayout {
    struct Slots {
        var left: [Widget]
        var afterSpaces: [Widget]
        var right: [Widget]
        var all: [Widget] { left + afterSpaces + right }
    }

    let root = NSView()
    private var groups: [GroupView] = []
    private var constraints: [NSLayoutConstraint] = []
    private var separatorObserver: NSKeyValueObservation?

    init() {
        root.translatesAutoresizingMaskIntoConstraints = false
    }

    func set(_ slots: Slots, theme: Theme) {
        NSLayoutConstraint.deactivate(constraints)
        constraints.removeAll()
        separatorObserver = nil
        root.subviews.forEach { $0.removeFromSuperview() }

        let left = GroupView(theme: theme, background: theme.roles.groupBg)
        let after = GroupView(theme: theme, background: theme.roles.groupBg)
        let right = GroupView(theme: theme, background: theme.roles.dataGroupBg, separator: theme.roles.dataSeparator)
        left.setChildren(slots.left.map(\.view))
        after.setChildren(slots.afterSpaces.map(\.view))
        right.setChildren(slots.right.map(\.view))
        groups = [left, after, right]

        var leadingViews: [NSView] = [left]
        if let color = theme.roles.groupSeparator {
            let sep = GroupView.hairline(color: color, height: 16)
            sep.isHidden = after.isHidden
            separatorObserver = after.observe(\.isHidden) { [weak sep] view, _ in sep?.isHidden = view.isHidden }
            leadingViews.append(sep)
        }
        leadingViews.append(after)
        let leading = NSStackView(views: leadingViews)
        leading.orientation = .horizontal
        leading.spacing = theme.metrics.groupGap
        leading.alignment = .centerY
        leading.detachesHiddenViews = true
        leading.translatesAutoresizingMaskIntoConstraints = false
        leading.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        root.addSubview(leading)
        root.addSubview(right)

        constraints = [
            leading.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: theme.metrics.leftInset),
            leading.centerYAnchor.constraint(equalTo: root.centerYAnchor),
            right.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -theme.metrics.rightInset),
            right.centerYAnchor.constraint(equalTo: root.centerYAnchor),
            leading.trailingAnchor.constraint(lessThanOrEqualTo: right.leadingAnchor, constant: -theme.metrics.groupGap),
        ]
        NSLayoutConstraint.activate(constraints)
    }
}
