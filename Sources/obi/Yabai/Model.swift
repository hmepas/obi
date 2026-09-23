import Foundation

struct Frame: Decodable, Equatable {
    let x: Double
    let y: Double
    let w: Double
    let h: Double
}

struct Space: Decodable, Equatable {
    let id: Int
    let index: Int
    let label: String
    let type: String
    let display: Int
    let windows: [Int]
    let hasFocus: Bool
    let isVisible: Bool
    let isNativeFullscreen: Bool

    enum CodingKeys: String, CodingKey {
        case id, index, label, type, display, windows
        case hasFocus = "has-focus"
        case isVisible = "is-visible"
        case isNativeFullscreen = "is-native-fullscreen"
    }
}

struct Window: Decodable, Equatable {
    let id: Int
    let pid: Int32
    let app: String
    let title: String
    let role: String
    let subrole: String
    let frame: Frame
    let display: Int
    let space: Int
    let stackIndex: Int
    let hasFocus: Bool
    let isVisible: Bool
    let isMinimized: Bool
    let isHidden: Bool
    let isSticky: Bool
    let isNativeFullscreen: Bool

    enum CodingKeys: String, CodingKey {
        case id, pid, app, title, role, subrole, frame, display, space
        case stackIndex = "stack-index"
        case hasFocus = "has-focus"
        case isVisible = "is-visible"
        case isMinimized = "is-minimized"
        case isHidden = "is-hidden"
        case isSticky = "is-sticky"
        case isNativeFullscreen = "is-native-fullscreen"
    }
}

struct Display: Decodable, Equatable {
    let id: Int
    let index: Int
    let label: String
    let frame: Frame
    let spaces: [Int]
    let hasFocus: Bool

    enum CodingKeys: String, CodingKey {
        case id, index, label, frame, spaces
        case hasFocus = "has-focus"
    }
}

extension Window {
    /// Panels and quick terminals (Ghostty cmd+/) are AXFloatingWindow: not real app windows.
    /// yabai also lists tooltips (role AXHelpTag) that can outlive the tooltip itself.
    var isPanel: Bool { role != "AXWindow" || subrole == "AXFloatingWindow" }
}

struct Snapshot: Equatable {
    var spaces: [Space] = []
    var windows: [Window] = []
    var displays: [Display] = []

    var focusedSpace: Space? { spaces.first { $0.hasFocus } }
    func window(id: Int) -> Window? { windows.first { $0.id == id } }
}
