import Foundation

enum YabaiKind: String, CaseIterable {
    case spaces, windows, displays
}

enum Event {
    case refresh(YabaiKind)
    case mode
    case reload
    case theme(String)
}

/// Main-thread event bus. HTTP server and signals emit; runtime and widgets subscribe.
final class Events {
    final class Subscription {
        private let cancelBlock: () -> Void
        fileprivate init(_ cancelBlock: @escaping () -> Void) { self.cancelBlock = cancelBlock }
        func cancel() { cancelBlock() }
        deinit { cancelBlock() }
    }

    private var handlers: [Int: (Event) -> Void] = [:]
    private var nextId = 0

    func on(_ handler: @escaping (Event) -> Void) -> Subscription {
        let id = nextId
        nextId += 1
        handlers[id] = handler
        return Subscription { [weak self] in self?.handlers[id] = nil }
    }

    func emit(_ event: Event) {
        DispatchQueue.main.async {
            for handler in self.handlers.values { handler(event) }
        }
    }
}
