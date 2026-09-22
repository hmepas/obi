import Foundation

/// Repeating timers on a utility queue. Blocks run off-main; callers hop to main for rendering.
final class Scheduler {
    final class Token {
        fileprivate let source: DispatchSourceTimer
        fileprivate init(_ source: DispatchSourceTimer) { self.source = source }
        func cancel() { source.cancel() }
        deinit { source.cancel() }
    }

    private let queue = DispatchQueue(label: "obi.scheduler", qos: .utility)

    /// Fires immediately (or at the next minute boundary when `alignToMinute`), then every `interval`.
    func every(_ interval: TimeInterval, alignToMinute: Bool = false, _ block: @escaping () -> Void) -> Token {
        let source = DispatchSource.makeTimerSource(queue: queue)
        let leeway: DispatchTimeInterval = alignToMinute ? .milliseconds(50) : .milliseconds(Int(min(interval, 2) * 250))
        if alignToMinute {
            let now = Date()
            let next = 60 - now.timeIntervalSince1970.truncatingRemainder(dividingBy: 60) + 0.05
            source.schedule(deadline: .now() + next, repeating: interval, leeway: leeway)
            queue.async(execute: block)
        } else {
            source.schedule(deadline: .now(), repeating: interval, leeway: leeway)
        }
        source.setEventHandler(handler: block)
        source.resume()
        return Token(source)
    }
}
