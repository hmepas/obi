import Foundation

/// `HH:mm`, refreshed on the minute boundary.
final class TimeWidget: PollingWidget<String> {
    override var interval: TimeInterval { 60 }
    override var alignToMinute: Bool { true }
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "HH:mm"
        return f
    }()

    override func fetch() throws -> String { formatter.string(from: Date()) }

    override func render(_ model: String) {
        pill.text = model
        pill.isHidden = false
    }
}
