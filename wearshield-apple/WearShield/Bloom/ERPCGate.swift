// ERPCGate — entropy-regulated power control
// Decides if a sensor reading is "interesting enough" to publish
// Saves battery by suppressing redundant transmissions

import Foundation

class ERPCGate {
    private var lastValues: [String: Double] = [:]
    private var tau: Double = 0.05  // adaptive threshold

    func shouldPublish(key: String, value: Double, batteryPct: Float) -> Bool {
        // widen gate when battery is low
        let batteryFactor = max(1.0, 3.0 - Double(batteryPct) * 2)
        let threshold = tau * batteryFactor

        guard let last = lastValues[key] else {
            lastValues[key] = value
            return true
        }

        let delta = abs(value - last)
        if delta > threshold {
            lastValues[key] = value
            return true
        }
        return false
    }

    func setTau(_ newTau: Double) {
        tau = max(0.01, min(1.0, newTau))
    }

    func reset() {
        lastValues = [:]
    }
}
