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

    init() {
        root.translatesAutoresizingMaskIntoConstraints = false
    }

    func set(_ slots: Slots, theme: Theme) {
        NSLayoutConstraint.deactivate(constraints)
        constraints.removeAll()
        groups.forEach { $0.removeFromSuperview() }

        let left = GroupView(theme: theme)
        let after = GroupView(theme: theme)
        let right = GroupView(theme: theme)
        left.setChildren(slots.left.map(\.view))
        after.setChildren(slots.afterSpaces.map(\.view))
        right.setChildren(slots.right.map(\.view))
        groups = [left, after, right]

        let leading = NSStackView(views: [left, after])
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
