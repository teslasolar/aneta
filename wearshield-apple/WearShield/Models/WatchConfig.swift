// WatchConfig — parameterized per Apple Watch model
// All values from Config.xcconfig at build time, overridable at runtime

import Foundation
import WatchKit

struct WatchConfig {
    static let shared = WatchConfig()

    let gatewayHost: String
    let gatewayPort: Int
    let mqttPort: Int
    let bridgePort: Int
    let wearer: String

    let hasSkinTemp: Bool
    let hasBloodOxygen: Bool
    let hasECG: Bool
    let hasDepth: Bool
    let hasSleepApnea: Bool

    let watchModel: String
    let watchSize: CGFloat

    let familyWearers: [String]
    let discoveryMode: String  // AUTO or STATIC

    init() {
        let info = { (key: String, fallback: String) -> String in
            Bundle.main.object(forInfoDictionaryKey: key) as? String ?? fallback
        }

        gatewayHost = info("GATEWAY_HOST", "10.0.0.25")
        gatewayPort = Int(info("GATEWAY_PORT", "5540")) ?? 5540
        mqttPort = Int(info("MQTT_PORT", "1883")) ?? 1883
        bridgePort = Int(info("WATCH_BRIDGE_PORT", "7272")) ?? 7272
        wearer = info("DEFAULT_WEARER", "user")

        hasSkinTemp = info("HAS_SKIN_TEMP", "NO") == "YES"
        hasBloodOxygen = info("HAS_BLOOD_OXYGEN", "NO") == "YES"
        hasECG = info("HAS_ECG", "NO") == "YES"
        hasDepth = info("HAS_DEPTH", "NO") == "YES"
        hasSleepApnea = info("HAS_SLEEP_APNEA", "NO") == "YES"

        familyWearers = info("FAMILY_WEARERS", "user")
            .split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        discoveryMode = info("DISCOVERY_MODE", "STATIC")

        let device = WKInterfaceDevice.current()
        watchModel = device.model
        watchSize = device.screenBounds.width
    }

    var gatewayURL: URL { URL(string: "http://\(gatewayHost):\(gatewayPort)")! }
    var blossomURL: URL { URL(string: "http://\(gatewayHost):\(gatewayPort)/blossom/call")! }
    var isAutoDiscovery: Bool { discoveryMode == "AUTO" }
}
