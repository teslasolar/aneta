// BloomState — fold mathematics + biomarker kernel
// Runs standalone (no gateway required) or syncs when gateway available

import Foundation
import Combine

let PRIMES: [Int] = [2, 3, 5, 7, 11, 13, 17]
let PHI: Double = (1.0 + sqrt(5.0)) / 2.0
let K_STAR: Double = 1.0 / PHI
let PRIMORIAL: Int = 510510

class BloomState: ObservableObject {
    @Published var bloom: [Double] = [1, 1, 1, 1, 1, 1, 1]
    @Published var fold: Int = PRIMORIAL
    @Published var phi: Double = 1.0
    @Published var kappa: Double = 0.5
    @Published var shield: String = "IDLE"
    @Published var wound: Int = 1
    @Published var emergence: Double = 0.0
    @Published var biomarkers: [String: BioReading] = [:]

    private var sensors: SensorHub?
    private var gateway: GatewayClient?
    private var modules: [BioModule] = []
    private var timer: Timer?

    func resetForWearer(_ wearer: WearerProfile) {
        bloom = [1, 1, 1, 1, 1, 1, 1]
        fold = PRIMORIAL; phi = 1.0; kappa = 0.5
        shield = "IDLE"; wound = 1; emergence = 0.0
        biomarkers = [:]
        modules.forEach { $0.reset() }
    }

    func link(sensors: SensorHub, gateway: GatewayClient?) {
        self.sensors = sensors
        self.gateway = gateway
        registerDefaultModules()
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func registerModule(_ module: BioModule) {
        modules.append(module)
    }

    private func registerDefaultModules() {
        modules = [
            PotassiumModule(),
            MagnesiumModule(),
            CalciumModule(),
            HydrationModule(),
            GlucoseModule(),
            CortisolModule(),
            HemoglobinModule(),
            InflammationModule(),
            AutonomicModule(),
            CrashRiskModule()
        ]
    }

    func tick() {
        guard let s = sensors else { return }

        // bloom from raw sensors
        let bands: [Double] = [
            s.heartRate / 200.0,
            s.hrv / 100.0,
            min(1, s.bloodOxygen / 100.0),
            s.stress,
            s.energy,
            s.skinTemp > 0 ? min(1, (s.skinTemp - 30) / 10) : 0.5,
            s.steps > 0 ? min(1, Double(s.steps) / 10000) : 0.1
        ]
        bloom = bands.map { max(1, min(5, 1 + $0 * 4)) }
        fold = bloomFold(bloom.map { Int(round($0)) })
        phi = bloomPhi(bloom)
        kappa = kappaStep(kappa, dt: 0.015)
        emergence = kappa >= K_STAR ? sqrt(kappa - K_STAR) : 0
        wound = bloomWound(bloom.map { Int(round($0)) })

        let lowCount = bloom.filter { $0 < 2 }.count
        shield = lowCount == 0 ? (kappa > 0.6 ? "BLOOMED" : "EXECUTE") :
                 lowCount > 4 ? "ABORTING" : lowCount > 2 ? "HOLDING" : "IDLE"

        // run all bio modules
        let input = SensorSnapshot(hr: s.heartRate, hrv: s.hrv, spo2: s.bloodOxygen,
                                   skinTemp: s.skinTemp, steps: s.steps, stress: s.stress,
                                   energy: s.energy, battery: s.batteryLevel, bloom: bloom)
        for mod in modules {
            let reading = mod.compute(input)
            biomarkers[mod.id] = reading
        }

        // sync to gateway if available (non-blocking, fire and forget)
        gateway?.sendSample(bloom: bloom, kappa: kappa, battery: s.batteryLevel)
    }

    private func kappaStep(_ k: Double, dt: Double) -> Double {
        let alpha = PHI + 2
        let gamma = pow(K_STAR, 5)
        let f = alpha * (k - K_STAR) * (1 - k) * k
        let noise = Double.random(in: -1...1) * gamma * sqrt(dt)
        return max(0.001, min(0.999, k + f * dt + noise))
    }

    func bloomFold(_ b: [Int]) -> Int {
        var f = 1
        for (i, e) in b.enumerated() where i < PRIMES.count {
            f *= Int(pow(Double(PRIMES[i]), Double(e)))
            if f > 10_000_000 { break }
        }
        return f
    }

    func bloomPhi(_ b: [Double]) -> Double {
        var s = 0.0
        for k in 0..<6 { s += max(0, 1 - abs((b[k + 1] / max(1, b[k])) - PHI)) }
        return s / 6
    }

    func bloomWound(_ b: [Int], tau: Int = 4) -> Int {
        var w = 1
        for (i, e) in b.enumerated() where i < PRIMES.count {
            if e < tau { w *= Int(pow(Double(PRIMES[i]), Double(tau - e))) }
            if w > 10_000_000 { break }
        }
        return w
    }
}
