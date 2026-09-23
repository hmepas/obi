import AppKit

/// Black band; spaces and the process row are macOS-style segmented controls (one dark track,
/// the focused segment lifted lighter); data widgets are plain text split by hairlines.
enum Segmented {
    static let theme: Theme = {
        let p = MaterialOcean.palette
        let track = NSColor(hex: 0x151722)
        return Theme(
            name: "segmented",
            palette: p,
            roles: Roles(
                text: p.fg,
                mutedText: p.fg.withAlphaComponent(0.5),
                barBg: .black,
                groupBg: track,
                dataGroupBg: .clear,
                pillBg: .clear,
                pillText: NSColor(hex: 0x7D8299),
                dataText: p.fg,
                dataIcon: NSColor(hex: 0x6F7590),
                timeText: p.white,
                focusedBg: NSColor(hex: 0x2C2F3D),
                focusedText: p.white,
                fullscreenBg: p.yellow,
                visibleRing: NSColor(hex: 0x3A3D4A),
                hoverRing: p.white.withAlphaComponent(0.25),
                layoutBadgeBg: p.blue,
                layoutBadgeText: p.bg,
                badgeText: p.bg,
                danger: p.red,
                separator: p.fg.withAlphaComponent(0.35),
                groupSeparator: nil,
                dataSeparator: NSColor(hex: 0x1E2130),
                sliderTrack: track
            ),
            font: Theme.monoFont(size: 12),
            metrics: Metrics(
                barHeight: 38,
                groupHeight: 24,
                groupRadius: 7,
                groupPaddingH: 2,
                groupGap: 10,
                pillHeight: 20,
                pillRadius: 5,
                pillPaddingH: 9,
                spacePaddingH: 8,
                gap: 0,
                iconGap: 6,
                iconSize: 13,
                spaceIconSize: 11,
                spaceIconGap: 5,
                leftInset: 10,
                rightInset: 8
            )
        )
    }()
}
