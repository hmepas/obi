import AppKit

enum MaterialOcean {
    static let palette = Palette(
        bg: NSColor(srgbRed: 15 / 255, green: 17 / 255, blue: 26 / 255, alpha: 1),
        bgAlt: NSColor(hex: 0x0F111A),
        minor: NSColor(hex: 0x3C3D3E),
        fg: NSColor(hex: 0xA6ACCD),
        white: NSColor(hex: 0xFFFFFF),
        red: NSColor(hex: 0xF07178),
        green: NSColor(hex: 0xC3E88D),
        yellow: NSColor(hex: 0xFFCB6B),
        orange: NSColor(hex: 0xF78C6C),
        blue: NSColor(hex: 0x82AAFF),
        magenta: NSColor(hex: 0xC792EA),
        cyan: NSColor(hex: 0x89DDFF)
    )

    static let theme = Theme(
        name: "material-ocean",
        palette: palette,
        roles: Roles(
            text: palette.fg,
            mutedText: palette.fg.withAlphaComponent(0.5),
            groupBg: palette.bg,
            pillBg: palette.minor,
            pillText: palette.fg,
            focusedBg: palette.fg,
            focusedText: palette.minor,
            fullscreenBg: palette.yellow,
            visibleRing: palette.fg.withAlphaComponent(0.6),
            hoverRing: palette.white.withAlphaComponent(0.75),
            layoutBadgeBg: palette.bgAlt,
            layoutBadgeText: palette.white,
            badgeText: palette.minor,
            danger: palette.red,
            separator: palette.fg.withAlphaComponent(0.35)
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
}
