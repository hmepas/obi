import CoreAudio
import Foundation

/// CoreAudio volume / mute for the default input and output devices.
enum Audio {
    enum Scope {
        case input, output

        var selector: AudioObjectPropertySelector {
            self == .input ? kAudioHardwarePropertyDefaultInputDevice : kAudioHardwarePropertyDefaultOutputDevice
        }
        var scope: AudioObjectPropertyScope {
            self == .input ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        }
    }

    static func defaultDevice(_ scope: Scope) -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(mSelector: scope.selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var device = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device)
        return status == noErr && device != 0 ? device : nil
    }

    /// 0–100, nil when the device exposes no volume control.
    static func volume(_ scope: Scope) -> Int? {
        guard let device = defaultDevice(scope) else { return nil }
        var values: [Float32] = []
        for element in volumeElements(device, scope) {
            var address = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyVolumeScalar, mScope: scope.scope, mElement: element)
            var value: Float32 = 0
            var size = UInt32(MemoryLayout<Float32>.size)
            if AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr { values.append(value) }
        }
        guard !values.isEmpty else { return nil }
        return Int((values.reduce(0, +) / Float32(values.count) * 100).rounded())
    }

    static func setVolume(_ scope: Scope, _ percent: Int) {
        guard let device = defaultDevice(scope) else { return }
        var value = Float32(max(0, min(100, percent))) / 100
        for element in volumeElements(device, scope) {
            var address = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyVolumeScalar, mScope: scope.scope, mElement: element)
            AudioObjectSetPropertyData(device, &address, 0, nil, UInt32(MemoryLayout<Float32>.size), &value)
        }
    }

    static func isMuted(_ scope: Scope) -> Bool {
        guard let device = defaultDevice(scope) else { return false }
        for element in [kAudioObjectPropertyElementMain, 1, 2] {
            var address = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyMute, mScope: scope.scope, mElement: element)
            guard AudioObjectHasProperty(device, &address) else { continue }
            var value: UInt32 = 0
            var size = UInt32(MemoryLayout<UInt32>.size)
            if AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr { return value != 0 }
        }
        return false
    }

    /// Main element when the device has a master volume, otherwise channels 1 and 2.
    private static func volumeElements(_ device: AudioDeviceID, _ scope: Scope) -> [AudioObjectPropertyElement] {
        var address = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyVolumeScalar, mScope: scope.scope, mElement: kAudioObjectPropertyElementMain)
        if AudioObjectHasProperty(device, &address) { return [kAudioObjectPropertyElementMain] }
        return [1, 2].filter { element in
            var a = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyVolumeScalar, mScope: scope.scope, mElement: element)
            return AudioObjectHasProperty(device, &a)
        }
    }
}
