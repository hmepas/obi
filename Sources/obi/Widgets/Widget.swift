import AppKit

protocol Widget: AnyObject {
    /// `view.isHidden == true` means the widget's threshold is not met; layout excludes it.
    var view: NSView { get }
    func start(_ ctx: Context)
    func stop()
}
