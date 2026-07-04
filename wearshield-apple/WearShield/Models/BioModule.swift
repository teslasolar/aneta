// BioModule — protocol for pluggable biomarker estimation modules
// Add a new biomarker: implement BioModule, register in BloomState.registerDefaultModules()

import Foundation

struct SensorSnapshot {
    let hr: Double       // bpm
    let hrv: Double      // ms RMSSD
    let spo2: Double     // % saturation
    let skinTemp: Double // celsius
    let steps: Int
    let stress: Double   // 0-1
    let energy: Double   // 0-1
    let battery: Float   // 0-1
    let bloom: [Double]  // 7-element fold vector
}

struct BioReading {
    let id: String
    let name: String
    let value: Double
    let unit: String
    let normalLo: Double
    let normalHi: Double
    let risk: Double         // 0-1, distance from normal weighted by trend
    let alertLevel: Int      // 0=green 1=yellow 2=orange 3=red
    let trend: Double        // positive=rising negative=falling
    let confidence: Double   // 0-1
    let message: String?     // optional alert message
}

protocol BioModule {
    var id: String { get }
    var name: String { get }
    var unit: String { get }
    var normalRange: ClosedRange<Double> { get }
    var criticalRange: ClosedRange<Double> { get }
    var sensorSources: [String] { get }

    func compute(_ input: SensorSnapshot) -> BioReading
    func reset()
}

extension BioModule {
    func alertLevel(risk: Double) -> Int {
        if risk > 0.7 { return 3 }
        if risk > 0.45 { return 2 }
        if risk > 0.2 { return 1 }
        return 0
    }

    func riskFromValue(_ value: Double) -> Double {
        if normalRange.contains(value) { return 0 }
        let lo = normalRange.lowerBound, hi = normalRange.upperBound
        let clo = criticalRange.lowerBound, chi = criticalRange.upperBound
        if value < lo { return min(1, (lo - value) / max(0.01, lo - clo)) }
        return min(1, (value - hi) / max(0.01, chi - hi))
    }
}
