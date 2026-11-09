import AppKit

/// simple-bar's look: a transparent 35 pt strip (pills centred between the screen edge and the windows), dark rounded groups, a grey pill per item.
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
                groupBg: .clear,
                dataGroupBg: .clear,
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
                barHeight: 35,
                groupHeight: 35,
                groupRadius: 17.5,
                groupPaddingH: 5,
                groupGap: 4,
                pillHeight: 25,
                pillRadius: 12.5,
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
