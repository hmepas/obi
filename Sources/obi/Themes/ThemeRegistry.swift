import Foundation

enum ThemeRegistry {
    static let all: [String: Theme] = [
        MaterialOcean.theme.name: MaterialOcean.theme,
    ]

    static let defaultName = MaterialOcean.theme.name

    static func get(_ name: String) -> Theme? { all[name] }
}
