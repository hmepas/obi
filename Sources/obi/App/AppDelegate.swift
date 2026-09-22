import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let runtime: Runtime

    init(options: Runtime.Options) {
        runtime = Runtime(options: options)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        runtime.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
