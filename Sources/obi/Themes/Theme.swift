import AppKit

struct Palette {
    let bg: NSColor       // "main" in simple-bar
    let bgAlt: NSColor    // "main-alt"
    let minor: NSColor
    let fg: NSColor
    let white: NSColor
    let red: NSColor
    let green: NSColor
    let yellow: NSColor
    let orange: NSColor
    let blue: NSColor
    let magenta: NSColor
    let cyan: NSColor

    /// Lookup by name as used by external data (Hammerspoon mode color).
    func color(named name: String) -> NSColor? {
        switch name.lowercased() {
        case "main", "bg", "background": return bg
        case "main-alt", "mainalt": return bgAlt
        case "minor": return minor
        case "foreground", "fg": return fg
        case "white": return white
        case "red": return red
        case "green": return green
        case "yellow": return yellow
        case "orange": return orange
        case "blue": return blue
        case "magenta": return magenta
        case "cyan": return cyan
        default: return nil
        }
    }
}

struct Roles {
    let text: NSColor
    let mutedText: NSColor
    let barBg: NSColor        // whole strip; clear = only the groups are painted
    let groupBg: NSColor      // background of the spaces / process groups
    let dataGroupBg: NSColor  // background of the data widget group
    let pillBg: NSColor
    let pillText: NSColor
    let dataText: NSColor
    let dataIcon: NSColor
    let timeText: NSColor
    let focusedBg: NSColor
    let focusedText: NSColor
    let fullscreenBg: NSColor
    let visibleRing: NSColor
    let hoverRing: NSColor
    let layoutBadgeBg: NSColor
    let layoutBadgeText: NSColor
    let badgeText: NSColor
    let danger: NSColor
    let separator: NSColor        // dot between displays in the spaces group
    let groupSeparator: NSColor?  // vertical hairline between spaces and process groups
    let dataSeparator: NSColor?   // vertical hairline between data widgets
    let sliderTrack: NSColor
}

struct Metrics {
    let barHeight: CGFloat
    let groupHeight: CGFloat
    let groupRadius: CGFloat
    let groupPaddingH: CGFloat
    let groupGap: CGFloat
    let pillHeight: CGFloat
    let pillRadius: CGFloat
    let pillPaddingH: CGFloat
    let spacePaddingH: CGFloat  // space labels sit in an <input> in simple-bar: 2 px extra each side
    let gap: CGFloat          // between pills in a group
    let iconGap: CGFloat      // between icon and text inside a pill
    let iconSize: CGFloat
    let spaceIconSize: CGFloat
    let spaceIconGap: CGFloat
    let leftInset: CGFloat
    let rightInset: CGFloat
}

struct Theme {
    let name: String
    let palette: Palette
    let roles: Roles
    let font: NSFont
    let metrics: Metrics

    static func monoFont(size: CGFloat) -> NSFont {
        NSFont(name: "Monaco", size: size) ?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }
}

extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
