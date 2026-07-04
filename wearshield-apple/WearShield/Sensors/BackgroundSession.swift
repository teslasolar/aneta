// BackgroundSession — keeps health monitoring alive in background
// Uses HKObserverQuery for background delivery of HR updates

import Foundation
import HealthKit

class BackgroundSession {
    private let store = HKHealthStore()
    private var queries: [HKObserverQuery] = []

    func enable() {
        observeInBackground(.heartRate)
        observeInBackground(.heartRateVariabilitySDNN)
        if WatchConfig.shared.hasBloodOxygen {
            observeInBackground(.oxygenSaturation)
        }
    }

    private func observeInBackground(_ id: HKQuantityTypeIdentifier) {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return }
        store.enableBackgroundDelivery(for: type, frequency: .immediate) { _, _ in }
        let query = HKObserverQuery(sampleType: type, predicate: nil) { _, completionHandler, _ in
            // new data arrived in background — post notification for BloomState to pick up
            NotificationCenter.default.post(name: .init("WearShieldBackgroundData"), object: id.rawValue)
            completionHandler()
        }
        store.execute(query)
        queries.append(query)
    }

    func disable() {
        queries.forEach { store.stop($0) }
        queries.removeAll()
    }
}
