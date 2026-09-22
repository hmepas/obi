import Foundation

/// Holds the latest yabai snapshot. `refresh(kind)` is debounced per kind (20 ms) and re-queries
/// only that kind; subscribers run on main whenever the snapshot actually changes.
final class YabaiStore {
    final class Subscription {
        private let cancelBlock: () -> Void
        fileprivate init(_ cancelBlock: @escaping () -> Void) { self.cancelBlock = cancelBlock }
        func cancel() { cancelBlock() }
        deinit { cancelBlock() }
    }

    let client: YabaiClient
    private(set) var snapshot = Snapshot()
    private var pending: [YabaiKind: DispatchWorkItem] = [:]
    private var handlers: [Int: (Snapshot) -> Void] = [:]
    private var nextId = 0
    private let debounce: TimeInterval = 0.02

    init(client: YabaiClient) { self.client = client }

    func subscribe(_ handler: @escaping (Snapshot) -> Void) -> Subscription {
        let id = nextId
        nextId += 1
        handlers[id] = handler
        return Subscription { [weak self] in self?.handlers[id] = nil }
    }

    func refresh(_ kind: YabaiKind) {
        pending[kind]?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.query(kind) }
        pending[kind] = item
        DispatchQueue.main.asyncAfter(deadline: .now() + debounce, execute: item)
    }

    func refreshAll() {
        for kind in YabaiKind.allCases { refresh(kind) }
    }

    private func query(_ kind: YabaiKind) {
        pending[kind] = nil
        switch kind {
        case .spaces:
            client.query(kind, as: [Space].self) { [weak self] in self?.apply { $0.spaces = $1 } ($0) }
        case .windows:
            client.query(kind, as: [Window].self) { [weak self] in self?.apply { $0.windows = $1 } ($0) }
        case .displays:
            client.query(kind, as: [Display].self) { [weak self] in self?.apply { $0.displays = $1 } ($0) }
        }
    }

    private func apply<T>(_ update: @escaping (inout Snapshot, T) -> Void) -> (T?) -> Void {
        return { [weak self] value in
            guard let self, let value else { return }
            var next = self.snapshot
            update(&next, value)
            guard next != self.snapshot else { return }
            self.snapshot = next
            for handler in self.handlers.values { handler(next) }
        }
    }
}
