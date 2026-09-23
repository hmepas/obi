import Darwin
import Foundation

/// Used memory % = 100 − kern.memorystatus_level (what `memory_pressure` prints).
final class MemoryWidget: PollingWidget<Int> {
    override var interval: TimeInterval { 4 }
    private var threshold = 50

    override func configure() {
        threshold = ctx.config.section("widgets.memory").int("threshold", 50)
        pill.setSymbol("square.stack.3d.up.fill")
    }

    override func fetch() throws -> Int {
        var level: Int32 = 0
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname("kern.memorystatus_level", &level, &size, nil, 0) == 0 else {
            throw Failure("sysctl kern.memorystatus_level: errno \(errno)")
        }
        return max(0, min(100, 100 - Int(level)))
    }

    override func render(_ model: Int) {
        pill.text = "\(model)%"
        pill.textColor = model > 70 ? ctx.theme.roles.danger : ctx.theme.roles.dataText
        pill.isHidden = model < threshold
    }
}
