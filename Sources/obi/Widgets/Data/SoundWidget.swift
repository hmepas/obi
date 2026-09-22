import Foundation

/// Output volume % with level/mute icon; hover shows a slider that sets the output volume.
final class SoundWidget: PollingWidget<SoundWidget.State> {
    struct State {
        let volume: Int?
        let muted: Bool
    }

    override var interval: TimeInterval { 20 }
    private var slider: InlineSlider!

    override func configure() {
        slider = InlineSlider(theme: ctx.theme)
        slider.attach(to: pill)
        slider.onChange = { [weak self] value in
            Audio.setVolume(.output, value)
            self?.render(State(volume: value, muted: Audio.isMuted(.output)))
        }
    }

    override func fetch() throws -> State {
        State(volume: Audio.volume(.output), muted: Audio.isMuted(.output))
    }

    override func render(_ model: State) {
        guard let volume = model.volume else {
            pill.isHidden = true
            return
        }
        let symbol: String
        if model.muted || volume == 0 { symbol = "speaker.slash.fill" }
        else if volume < 20 { symbol = "speaker.fill" }
        else if volume < 50 { symbol = "speaker.wave.1.fill" }
        else { symbol = "speaker.wave.2.fill" }
        pill.setSymbol(symbol)
        pill.text = "\(volume)%"
        slider.setValue(volume)
        pill.isHidden = false
    }
}
