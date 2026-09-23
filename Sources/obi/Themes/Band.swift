import AppKit

/// Native menu bar look: a black band the full height of the notch strip, system font, text on
/// black; only the focused space / window gets a soft highlight, like a Tahoe menu item.
enum Band {
    static let theme: Theme = {
        let p = MaterialOcean.palette
        let highlight = NSColor(hex: 0x2A2C36)
        return Theme(
            name: "band",
            palette: p,
            roles: Roles(
                text: p.fg,
                mutedText: p.fg.withAlphaComponent(0.5),
                barBg: .black,
                groupBg: .clear,
                dataGroupBg: .clear,
                pillBg: .clear,
                pillText: NSColor(hex: 0x8E93AD),
                dataText: NSColor(hex: 0xD3D6E6),
                dataIcon: NSColor(hex: 0xA4A8BD),
                timeText: p.white,
                focusedBg: highlight,
                focusedText: p.white,
                fullscreenBg: p.yellow,
                visibleRing: NSColor(hex: 0x3A3D4A),
                hoverRing: p.white.withAlphaComponent(0.25),
                layoutBadgeBg: .clear,
                layoutBadgeText: p.blue,
                badgeText: p.bg,
                danger: p.red,
                separator: p.fg.withAlphaComponent(0.35),
                groupSeparator: highlight,
                dataSeparator: nil,
                sliderTrack: highlight
            ),
            font: NSFont.systemFont(ofSize: 13, weight: .medium),
            metrics: Metrics(
                barHeight: 38,
                groupHeight: 26,
                groupRadius: 0,
                groupPaddingH: 0,
                groupGap: 14,
                pillHeight: 22,
                pillRadius: 6,
                pillPaddingH: 9,
                spacePaddingH: 8,
                gap: 2,
                iconGap: 6,
                iconSize: 13,
                spaceIconSize: 12,
                spaceIconGap: 5,
                leftInset: 12,
                rightInset: 10
            )
        )
    }()
}
