import AppKit

/// The one palette every theme draws from (simple-bar's Material Ocean).
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
}
