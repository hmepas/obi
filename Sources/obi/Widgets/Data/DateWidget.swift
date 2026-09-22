import Foundation

/// `Tue 22 Sep`. Click opens Calendar.
final class DateWidget: PollingWidget<String> {
    override var interval: TimeInterval { 30 }
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "EEE d MMM"
        return f
    }()

    override func configure() {
        pill.onClick = { [weak self] _ in self?.ctx.shell.open(app: "Calendar") }
    }

    override func fetch() throws -> String { formatter.string(from: Date()) }

    override func render(_ model: String) {
        pill.text = model
        pill.isHidden = false
    }
}
