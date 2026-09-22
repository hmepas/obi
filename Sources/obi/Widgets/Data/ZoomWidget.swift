import AppKit

/// Visible only while zoom.us is in a meeting: mic and camera state via the Meeting menu (UI scripting).
final class ZoomWidget: PollingWidget<ZoomWidget.State> {
    enum State {
        case none
        case meeting(micOn: Bool, videoOn: Bool)
    }

    override var interval: TimeInterval { 5 }
    private var videoIcon: NSImageView!

    private static let script = """
    tell application "System Events"
        if not (exists process "zoom.us") then return "none"
        tell process "zoom.us"
            if not (exists menu bar item "Meeting" of menu bar 1) then return "none"
            set m to menu 1 of menu bar item "Meeting" of menu bar 1
            set micOn to exists menu item "Mute audio" of m
            set videoOn to exists menu item "Stop video" of m
            return (micOn as string) & "," & (videoOn as string)
        end tell
    end tell
    """

    override func configure() {
        pill.setSymbol("mic.fill")
        videoIcon = pill.addSymbol("video.fill")
    }

    override func fetch() throws -> State {
        guard !NSRunningApplication.runningApplications(withBundleIdentifier: "us.zoom.xos").isEmpty else { return .none }
        let out = ctx.shell.osascript(Self.script)
        guard out.ok else { throw Failure(out.stderr.trimmingCharacters(in: .whitespacesAndNewlines)) }
        let parts = out.stdout.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ",")
        guard parts.count == 2 else { return .none }
        return .meeting(micOn: parts[0] == "true", videoOn: parts[1] == "true")
    }

    override func render(_ model: State) {
        switch model {
        case .none:
            pill.isHidden = true
        case .meeting(let micOn, let videoOn):
            pill.setSymbol(micOn ? "mic.fill" : "mic.slash.fill")
            pill.symbolColor = micOn ? ctx.theme.roles.pillText : ctx.theme.roles.danger
            videoIcon.image = PillView.symbolImage(videoOn ? "video.fill" : "video.slash.fill", size: ctx.theme.metrics.iconSize)
            videoIcon.contentTintColor = videoOn ? ctx.theme.roles.pillText : ctx.theme.roles.danger
            pill.text = ""
            pill.isHidden = false
        }
    }
}
