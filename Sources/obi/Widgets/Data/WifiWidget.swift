import CoreWLAN
import Foundation
import SystemConfiguration

/// SSID of the configured interface; hidden when Wi-Fi is off. Right click opens Network settings.
/// CoreWLAN and `ipconfig` redact the SSID without Location permission, but the dynamic store's
/// cached scan record for the interface still carries it.
final class WifiWidget: PollingWidget<String?> {
    override var interval: TimeInterval { 20 }
    private var device = "en0"

    override func configure() {
        device = ctx.config.section("widgets.wifi").string("device", "en0")
        pill.setSymbol("wifi")
        pill.onRightClick = { [weak self] _ in
            self?.ctx.shell.open(url: "x-apple.systempreferences:com.apple.Network-Settings.extension")
        }
    }

    override func fetch() throws -> String? {
        guard let iface = CWWiFiClient.shared().interface(withName: device) else { throw Failure("no interface \(device)") }
        guard iface.powerOn() else { return nil }
        guard iface.wlanChannel() != nil else { return "" } // powered on, not associated
        if let ssid = iface.ssid(), !ssid.isEmpty { return ssid }
        return Self.ssidFromDynamicStore(device) ?? ""
    }

    static func ssidFromDynamicStore(_ device: String) -> String? {
        guard let store = SCDynamicStoreCreate(nil, "obi" as CFString, nil, nil),
              let state = SCDynamicStoreCopyValue(store, "State:/Network/Interface/\(device)/AirPort" as CFString) as? [String: Any]
        else { return nil }
        if let ssid = state["SSID_STR"] as? String, !ssid.isEmpty { return ssid }
        guard let data = state["CachedScanRecord"] as? Data,
              let record = try? NSKeyedUnarchiver.unarchivedObject(
                  ofClasses: [NSDictionary.self, NSString.self, NSData.self, NSArray.self, NSNumber.self], from: data
              ) as? [String: Any],
              let ssid = record["SSID_STR"] as? String, !ssid.isEmpty
        else { return nil }
        return ssid
    }

    override func render(_ model: String?) {
        guard let ssid = model else {
            pill.isHidden = true
            return
        }
        pill.text = ssid.isEmpty ? "—" : ssid
        pill.isHidden = false
    }
}
