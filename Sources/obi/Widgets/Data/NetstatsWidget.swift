import Foundation

/// Download / upload rate from interface byte counters (getifaddrs deltas). Hidden below threshold.
final class NetstatsWidget: PollingWidget<NetstatsWidget.Rates> {
    struct Rates {
        let down: Double // bytes/s
        let up: Double
    }

    override var interval: TimeInterval { 2 }
    private var previous: [String: (UInt32, UInt32)] = [:]
    private var previousTime = Date()
    private var thresholdBytes: Double = 0

    override func configure() {
        thresholdBytes = Double(ctx.config.section("widgets.netstats").int("threshold", 1500)) * 1024
        pill.setSymbol("arrow.up.arrow.down")
    }

    override func fetch() throws -> Rates {
        var list: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&list) == 0 else { throw Failure("getifaddrs failed") }
        defer { freeifaddrs(list) }
        var current: [String: (UInt32, UInt32)] = [:]
        var cursor = list
        while let entry = cursor {
            let ifa = entry.pointee
            cursor = ifa.ifa_next
            guard let addr = ifa.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK), let data = ifa.ifa_data else { continue }
            let name = String(cString: ifa.ifa_name)
            if name.hasPrefix("lo") { continue }
            let stats = data.assumingMemoryBound(to: if_data.self).pointee
            current[name] = (stats.ifi_ibytes, stats.ifi_obytes)
        }
        let now = Date()
        let elapsed = now.timeIntervalSince(previousTime)
        var down: UInt64 = 0, up: UInt64 = 0
        for (name, (i, o)) in current {
            guard let (pi, po) = previous[name] else { continue }
            down += UInt64(i &- pi)
            up += UInt64(o &- po)
        }
        let hadPrevious = !previous.isEmpty
        previous = current
        previousTime = now
        guard hadPrevious, elapsed > 0 else { return Rates(down: 0, up: 0) }
        return Rates(down: Double(down) / elapsed, up: Double(up) / elapsed)
    }

    override func render(_ model: Rates) {
        guard model.down >= thresholdBytes || model.up >= thresholdBytes else {
            pill.isHidden = true
            return
        }
        pill.text = "↓\(Self.format(model.down)) ↑\(Self.format(model.up))"
        pill.isHidden = false
    }

    static func format(_ bytes: Double) -> String {
        if bytes < 1024 { return "\(Int(bytes))b" }
        if bytes < 1024 * 1024 { return String(format: "%.1fkb", bytes / 1024) }
        return String(format: "%.1fmb", bytes / 1024 / 1024)
    }
}
