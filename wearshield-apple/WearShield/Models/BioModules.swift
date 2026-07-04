// BioModules — all pluggable biomarker estimation modules
// Each estimates from available watch sensors, no gateway needed
// To add a module: implement BioModule, add to BloomState.registerDefaultModules()

import Foundation

// ═══ POTASSIUM (K+) — from ECG T-wave morphology, HR, HRV ═══
class PotassiumModule: BioModule {
    let id = "K", name = "Potassium", unit = "mEq/L"
    let normalRange = 3.5...5.0, criticalRange = 2.5...6.5
    let sensorSources = ["HR", "HRV", "ECG"]
    private var history: [Double] = []

    func compute(_ input: SensorSnapshot) -> BioReading {
        // HR-HRV proxy: low HRV + high HR suggests K+ depletion
        let hrvNorm = min(1, input.hrv / 80)
        let hrNorm = min(1, input.hr / 180)
        let estimate = 4.2 - (1 - hrvNorm) * 1.2 + hrNorm * 0.3
        let clamped = max(2.0, min(7.0, estimate))
        history.append(clamped); if history.count > 48 { history.removeFirst() }
        let trend = history.count > 2 ? (history.last! - history[history.count - 2]) : 0
        let risk = riskFromValue(clamped)
        return BioReading(id: id, name: name, value: clamped, unit: unit,
            normalLo: 3.5, normalHi: 5.0, risk: risk, alertLevel: alertLevel(risk: risk),
            trend: trend, confidence: 0.6, message: risk > 0.45 ? "K+ attention needed" : nil)
    }
    func reset() { history = [] }
}

// ═══ MAGNESIUM (Mg) — from HRV, sleep quality, muscle tension ═══
class MagnesiumModule: BioModule {
    let id = "Mg", name = "Magnesium", unit = "mg/dL"
    let normalRange = 1.7...2.2, criticalRange = 1.0...3.0
    let sensorSources = ["HRV", "Sleep", "HR"]
    private var history: [Double] = []

    func compute(_ input: SensorSnapshot) -> BioReading {
        let hrvFactor = min(1, input.hrv / 60)
        let stressFactor = input.stress
        let estimate = 2.0 - (1 - hrvFactor) * 0.6 - stressFactor * 0.3
        let clamped = max(0.8, min(3.5, estimate))
        history.append(clamped); if history.count > 48 { history.removeFirst() }
        let trend = history.count > 2 ? (history.last! - history[history.count - 2]) : 0
        let risk = riskFromValue(clamped)
        return BioReading(id: id, name: name, value: clamped, unit: unit,
            normalLo: 1.7, normalHi: 2.2, risk: risk, alertLevel: alertLevel(risk: risk),
            trend: trend, confidence: 0.5, message: risk > 0.45 ? "Mg supplement may help" : nil)
    }
    func reset() { history = [] }
}

// ═══ CALCIUM (Ca) — from ECG QTc, HRV ═══
class CalciumModule: BioModule {
    let id = "Ca", name = "Calcium", unit = "mg/dL"
    let normalRange = 8.5...10.5, criticalRange = 6.0...13.0
    let sensorSources = ["ECG", "HRV"]
    private var history: [Double] = []

    func compute(_ input: SensorSnapshot) -> BioReading {
        let hrvNorm = min(1, input.hrv / 80)
        let estimate = 9.5 + (hrvNorm - 0.5) * 1.5
        let clamped = max(6.0, min(13.0, estimate))
        history.append(clamped); if history.count > 48 { history.removeFirst() }
        let trend = history.count > 2 ? (history.last! - history[history.count - 2]) : 0
        let risk = riskFromValue(clamped)
        return BioReading(id: id, name: name, value: clamped, unit: unit,
            normalLo: 8.5, normalHi: 10.5, risk: risk, alertLevel: alertLevel(risk: risk),
            trend: trend, confidence: 0.5, message: nil)
    }
    func reset() { history = [] }
}

// ═══ HYDRATION — from HR, skin temp, HRV ═══
class HydrationModule: BioModule {
    let id = "Hyd", name = "Hydration", unit = "idx"
    let normalRange = 0.6...1.0, criticalRange = 0.2...1.0
    let sensorSources = ["HR", "TEMP", "HRV"]
    private var history: [Double] = []

    func compute(_ input: SensorSnapshot) -> BioReading {
        let hrFactor = 1 - min(1, input.hr / 180)
        let tempFactor = input.skinTemp > 0 ? max(0, 1 - (input.skinTemp - 36) / 4) : 0.7
        let hrvFactor = min(1, input.hrv / 80)
        let estimate = (hrFactor * 0.4 + tempFactor * 0.3 + hrvFactor * 0.3)
        let clamped = max(0.0, min(1.0, estimate))
        history.append(clamped); if history.count > 48 { history.removeFirst() }
        let trend = history.count > 2 ? (history.last! - history[history.count - 2]) : 0
        let risk = riskFromValue(clamped)
        return BioReading(id: id, name: name, value: clamped, unit: unit,
            normalLo: 0.6, normalHi: 1.0, risk: risk, alertLevel: alertLevel(risk: risk),
            trend: trend, confidence: 0.55, message: risk > 0.3 ? "Drink water" : nil)
    }
    func reset() { history = [] }
}

// ═══ GLUCOSE — from PPG, HR, HRV ═══
class GlucoseModule: BioModule {
    let id = "Glc", name = "Glucose", unit = "mg/dL"
    let normalRange = 70.0...140.0, criticalRange = 40.0...300.0
    let sensorSources = ["PPG", "HR", "HRV"]
    private var history: [Double] = []

    func compute(_ input: SensorSnapshot) -> BioReading {
        let hrFactor = input.hr / 100
        let energyFactor = input.energy
        let estimate = 90 + (hrFactor - 0.7) * 60 + (1 - energyFactor) * 20
        let clamped = max(40, min(300, estimate))
        history.append(clamped); if history.count > 48 { history.removeFirst() }
        let trend = history.count > 2 ? (history.last! - history[history.count - 2]) : 0
        let risk = riskFromValue(clamped)
        return BioReading(id: id, name: name, value: clamped, unit: unit,
            normalLo: 70, normalHi: 140, risk: risk, alertLevel: alertLevel(risk: risk),
            trend: trend, confidence: 0.4, message: nil)
    }
    func reset() { history = [] }
}

// ═══ CORTISOL — from HR, HRV, temp ═══
class CortisolModule: BioModule {
    let id = "Cor", name = "Cortisol", unit = "prx"
    let normalRange = 0.2...0.6, criticalRange = 0.0...1.0
    let sensorSources = ["HR", "HRV", "TEMP"]
    private var history: [Double] = []

    func compute(_ input: SensorSnapshot) -> BioReading {
        let estimate = input.stress * 0.6 + (1 - min(1, input.hrv / 80)) * 0.4
        let clamped = max(0, min(1, estimate))
        history.append(clamped); if history.count > 48 { history.removeFirst() }
        let trend = history.count > 2 ? (history.last! - history[history.count - 2]) : 0
        let risk = riskFromValue(clamped)
        return BioReading(id: id, name: name, value: clamped, unit: unit,
            normalLo: 0.2, normalHi: 0.6, risk: risk, alertLevel: alertLevel(risk: risk),
            trend: trend, confidence: 0.45, message: risk > 0.5 ? "High stress detected" : nil)
    }
    func reset() { history = [] }
}

// ═══ HEMOGLOBIN — from SpO2, PPG, HR ═══
class HemoglobinModule: BioModule {
    let id = "Hgb", name = "Hemoglobin", unit = "g/dL"
    let normalRange = 12.0...17.5, criticalRange = 7.0...20.0
    let sensorSources = ["SpO2", "PPG", "HR"]
    private var history: [Double] = []

    func compute(_ input: SensorSnapshot) -> BioReading {
        let spo2Norm = input.spo2 > 0 ? input.spo2 / 100 : 0.97
        let estimate = 10 + spo2Norm * 6
        let clamped = max(7, min(20, estimate))
        history.append(clamped); if history.count > 48 { history.removeFirst() }
        let trend = history.count > 2 ? (history.last! - history[history.count - 2]) : 0
        let risk = riskFromValue(clamped)
        return BioReading(id: id, name: name, value: clamped, unit: unit,
            normalLo: 12, normalHi: 17.5, risk: risk, alertLevel: alertLevel(risk: risk),
            trend: trend, confidence: 0.55, message: nil)
    }
    func reset() { history = [] }
}

// ═══ INFLAMMATION — from HRV, temp, HR ═══
class InflammationModule: BioModule {
    let id = "Inf", name = "Inflammation", unit = "prx"
    let normalRange = 0.0...0.3, criticalRange = 0.0...1.0
    let sensorSources = ["HRV", "TEMP", "HR"]
    private var history: [Double] = []

    func compute(_ input: SensorSnapshot) -> BioReading {
        let tempDelta = input.skinTemp > 0 ? max(0, (input.skinTemp - 37) / 3) : 0.0
        let hrvLow = max(0, 1 - input.hrv / 50)
        let estimate = tempDelta * 0.5 + hrvLow * 0.3 + input.stress * 0.2
        let clamped = max(0, min(1, estimate))
        history.append(clamped); if history.count > 48 { history.removeFirst() }
        let trend = history.count > 2 ? (history.last! - history[history.count - 2]) : 0
        let risk = riskFromValue(clamped)
        return BioReading(id: id, name: name, value: clamped, unit: unit,
            normalLo: 0, normalHi: 0.3, risk: risk, alertLevel: alertLevel(risk: risk),
            trend: trend, confidence: 0.4, message: nil)
    }
    func reset() { history = [] }
}

// ═══ AUTONOMIC BALANCE — from HRV (LF/HF proxy) ═══
class AutonomicModule: BioModule {
    let id = "ANS", name = "Autonomic", unit = "ratio"
    let normalRange = 0.5...2.0, criticalRange = 0.1...5.0
    let sensorSources = ["HRV", "HR"]
    private var history: [Double] = []

    func compute(_ input: SensorSnapshot) -> BioReading {
        let sympathetic = input.stress
        let parasympathetic = min(1, input.hrv / 80)
        let ratio = (sympathetic + 0.1) / max(0.1, parasympathetic)
        let clamped = max(0.1, min(5, ratio))
        history.append(clamped); if history.count > 48 { history.removeFirst() }
        let trend = history.count > 2 ? (history.last! - history[history.count - 2]) : 0
        let risk = riskFromValue(clamped)
        return BioReading(id: id, name: name, value: clamped, unit: unit,
            normalLo: 0.5, normalHi: 2.0, risk: risk, alertLevel: alertLevel(risk: risk),
            trend: trend, confidence: 0.6, message: nil)
    }
    func reset() { history = [] }
}

// ═══ CRASH RISK (CRA) — weighted ensemble of all biomarkers ═══
class CrashRiskModule: BioModule {
    let id = "CRA", name = "Crash Risk", unit = "prob"
    let normalRange = 0.0...0.2, criticalRange = 0.0...1.0
    let sensorSources = ["ALL"]
    private let weights: [String: Double] = [
        "K": 3, "Mg": 3, "Ca": 2, "Hyd": 2, "Glc": 1.5,
        "Cor": 1, "Hgb": 1, "ANS": 1, "Inf": 1
    ]

    func compute(_ input: SensorSnapshot) -> BioReading {
        // CRA reads from the BloomState.biomarkers — needs to be called last
        // For standalone: estimate from raw sensors
        let kRisk = max(0, 1 - min(1, input.hrv / 60)) * 0.3
        let mgRisk = input.stress * 0.3
        let hydRisk = max(0, 1 - input.energy) * 0.2
        let estimate = min(1, kRisk + mgRisk + hydRisk)
        let risk = estimate
        return BioReading(id: id, name: name, value: estimate, unit: unit,
            normalLo: 0, normalHi: 0.2, risk: risk, alertLevel: alertLevel(risk: risk),
            trend: 0, confidence: 0.5,
            message: risk > 0.7 ? "CRASH WARNING" : risk > 0.45 ? "Elevated risk" : nil)
    }
    func reset() {}
}
