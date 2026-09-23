import Foundation

enum ThemeRegistry {
    static let all: [String: Theme] = [
        Pills.theme.name: Pills.theme,
        Band.theme.name: Band.theme,
        Segmented.theme.name: Segmented.theme,
    ]

    static let defaultName = Pills.theme.name

    static func get(_ name: String) -> Theme? { all[name] }
}
