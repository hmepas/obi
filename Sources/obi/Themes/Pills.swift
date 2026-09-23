import AppKit

/// simple-bar's look: a transparent 28 px strip, dark rounded groups, a grey pill per item.
enum Pills {
    static let theme: Theme = {
        let p = MaterialOcean.palette
        return Theme(
            name: "pills",
            palette: p,
            roles: Roles(
                text: p.fg,
                mutedText: p.fg.withAlphaComponent(0.5),
                barBg: .clear,
                groupBg: p.bg,
                dataGroupBg: p.bg,
                pillBg: p.minor,
                pillText: p.fg,
                dataText: p.fg,
                dataIcon: p.fg,
                timeText: p.fg,
                focusedBg: p.fg,
                focusedText: p.minor,
                fullscreenBg: p.yellow,
                visibleRing: p.fg.withAlphaComponent(0.6),
                hoverRing: p.white.withAlphaComponent(0.75),
                layoutBadgeBg: p.bgAlt,
                layoutBadgeText: p.white,
                badgeText: p.minor,
                danger: p.red,
                separator: p.fg.withAlphaComponent(0.35),
                groupSeparator: nil,
                dataSeparator: nil,
                sliderTrack: p.bg
            ),
            font: Theme.monoFont(size: 12),
            metrics: Metrics(
                barHeight: 28,
                groupHeight: 28,
                groupRadius: 14,
                groupPaddingH: 5,
                groupGap: 4,
                pillHeight: 20,
                pillRadius: 10,
                pillPaddingH: 7,
                spacePaddingH: 9,
                gap: 5,
                iconGap: 6,
                iconSize: 13,
                spaceIconSize: 11,
                spaceIconGap: 6,
                leftInset: 0,
                rightInset: 9
            )
        )
    }()
}
