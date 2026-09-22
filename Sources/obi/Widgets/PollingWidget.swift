import AppKit

/// Base for timer-driven data widgets: `fetch()` runs on a background queue every `interval`,
/// `render(_:)` runs on main. Subclasses override `configure()` to build the pill.
class PollingWidget<Model>: Widget {
    let pill: DataPill
    var view: NSView { pill }
    var ctx: Context!
    var interval: TimeInterval { 60 }
    var alignToMinute: Bool { false }

    private var token: Scheduler.Token?
    private var failureLogged = false

    init(theme: Theme) {
        pill = DataPill(theme: theme)
        pill.isHidden = true
    }

    func start(_ ctx: Context) {
        self.ctx = ctx
        configure()
        token = ctx.scheduler.every(interval, alignToMinute: alignToMinute) { [weak self] in
            guard let self else { return }
            do {
                let model = try self.fetch()
                DispatchQueue.main.async { self.render(model) }
            } catch {
                if !self.failureLogged {
                    self.failureLogged = true
                    ctx.log.error("\(type(of: self)): fetch failed: \(error)")
                }
                DispatchQueue.main.async { self.pill.isHidden = true }
            }
        }
    }

    func stop() {
        token?.cancel()
        token = nil
    }

    /// Called on main once before the first fetch.
    func configure() {}
    func fetch() throws -> Model { fatalError("override") }
    func render(_ model: Model) {}

    struct Failure: Error, CustomStringConvertible {
        let description: String
        init(_ d: String) { description = d }
    }
}
