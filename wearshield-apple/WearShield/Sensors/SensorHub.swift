// SensorHub — HealthKit + CoreMotion sensor collection
// Parameterized by WatchConfig for available sensors per model

import Foundation
import HealthKit
import CoreMotion
import Combine

class SensorHub: ObservableObject {
    @Published var heartRate: Double = 0
    @Published var hrv: Double = 0
    @Published var bloodOxygen: Double = 0
    @Published var skinTemp: Double = 0
    @Published var steps: Int = 0
    @Published var stress: Double = 0
    @Published var energy: Double = 0.5
    @Published var activeCalories: Double = 0
    @Published var batteryLevel: Float = 1.0
    @Published var isAuthorized = false

    private let healthStore = HKHealthStore()
    private let motionManager = CMMotionManager()
    private let config = WatchConfig.shared
    private var queries: [HKQuery] = []

    func start() {
        requestAuthorization()
        startBatteryMonitoring()
        startMotion()
    }

    private func requestAuthorization() {
        var readTypes: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        if config.hasBloodOxygen {
            readTypes.insert(HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!)
        }
        if config.hasSkinTemp {
            if #available(watchOS 9.0, *) {
                readTypes.insert(HKQuantityType.quantityType(forIdentifier: .appleSleepingWristTemperature)!)
            }
        }
        if config.hasECG {
            readTypes.insert(HKObjectType.electrocardiogramType())
        }

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] ok, _ in
            DispatchQueue.main.async {
                self?.isAuthorized = ok
                if ok { self?.startHealthQueries() }
            }
        }
    }

    private func startHealthQueries() {
        observeHeartRate()
        observeHRV()
        observeSteps()
        if config.hasBloodOxygen { observeBloodOxygen() }
    }

    private func observeHeartRate() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let query = HKAnchoredObjectQuery(type: type, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) {
            [weak self] _, samples, _, _, _ in
            self?.processHR(samples as? [HKQuantitySample])
        }
        query.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processHR(samples as? [HKQuantitySample])
        }
        healthStore.execute(query)
        queries.append(query)
    }

    private func processHR(_ samples: [HKQuantitySample]?) {
        guard let last = samples?.last else { return }
        let bpm = last.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        DispatchQueue.main.async {
            self.heartRate = bpm
            self.stress = max(0, min(1, (bpm - 60) / 80))
            self.energy = max(0, min(1, 1 - self.stress))
        }
    }

    private func observeHRV() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        let query = HKAnchoredObjectQuery(type: type, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) {
            [weak self] _, samples, _, _, _ in
            if let last = (samples as? [HKQuantitySample])?.last {
                let ms = last.quantity.doubleValue(for: .secondUnit(with: .milli))
                DispatchQueue.main.async { self?.hrv = ms }
            }
        }
        query.updateHandler = { [weak self] _, samples, _, _, _ in
            if let last = (samples as? [HKQuantitySample])?.last {
                let ms = last.quantity.doubleValue(for: .secondUnit(with: .milli))
                DispatchQueue.main.async { self?.hrv = ms }
            }
        }
        healthStore.execute(query)
        queries.append(query)
    }

    private func observeBloodOxygen() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else { return }
        let query = HKAnchoredObjectQuery(type: type, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) {
            [weak self] _, samples, _, _, _ in
            if let last = (samples as? [HKQuantitySample])?.last {
                let pct = last.quantity.doubleValue(for: .percent()) * 100
                DispatchQueue.main.async { self?.bloodOxygen = pct }
            }
        }
        query.updateHandler = { [weak self] _, samples, _, _, _ in
            if let last = (samples as? [HKQuantitySample])?.last {
                let pct = last.quantity.doubleValue(for: .percent()) * 100
                DispatchQueue.main.async { self?.bloodOxygen = pct }
            }
        }
        healthStore.execute(query)
        queries.append(query)
    }

    private func observeSteps() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let pred = HKQuery.predicateForSamples(withStart: start, end: nil)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: pred, options: .cumulativeSum) {
            [weak self] _, stats, _ in
            let count = Int(stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            DispatchQueue.main.async { self?.steps = count }
        }
        healthStore.execute(query)
    }

    private func startMotion() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 1.0 / 25.0
            motionManager.startAccelerometerUpdates()
        }
    }

    private func startBatteryMonitoring() {
        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.batteryLevel = WKInterfaceDevice.current().batteryLevel
            }
        }
    }

    func stop() {
        queries.forEach { healthStore.stop($0) }
        queries.removeAll()
        motionManager.stopAccelerometerUpdates()
    }
}
