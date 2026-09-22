import Foundation

/// Input volume % with on/off icon; hover shows a slider that sets the input volume.
final class MicWidget: PollingWidget<Int?> {
    override var interval: TimeInterval { 20 }
    private var slider: InlineSlider!

    override func configure() {
        slider = InlineSlider(theme: ctx.theme)
        slider.attach(to: pill)
        slider.onChange = { [weak self] value in
            Audio.setVolume(.input, value)
            self?.render(value)
        }
    }

    override func fetch() throws -> Int? { Audio.volume(.input) }

    override func render(_ model: Int?) {
        guard let volume = model else {
            pill.isHidden = true
            return
        }
        pill.setSymbol(volume > 0 ? "mic.fill" : "mic.slash.fill")
        pill.text = "\(volume)%"
        slider.setValue(volume)
        pill.isHidden = false
    }
}
