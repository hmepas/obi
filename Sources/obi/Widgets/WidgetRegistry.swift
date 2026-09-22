import Foundation

/// The only place that knows which widgets exist and where they sit.
enum WidgetRegistry {
    static func make(_ ctx: Context) -> BarLayout.Slots {
        let t = ctx.theme
        return .init(
            left: [SpacesWidget(theme: t)],
            afterSpaces: [ProcessWidget(theme: t)],
            right: [
                ZoomWidget(theme: t), NetstatsWidget(theme: t), CpuWidget(theme: t), MemoryWidget(theme: t),
                MicWidget(theme: t), SoundWidget(theme: t), WifiWidget(theme: t), KeyboardWidget(theme: t),
                DateWidget(theme: t), TimeWidget(theme: t),
            ]
        )
    }
}
