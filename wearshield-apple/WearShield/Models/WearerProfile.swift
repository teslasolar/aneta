// WearerProfile — per-wearer state for family unit
// Each watch can serve any family member — switch at runtime

import Foundation

struct WearerProfile: Identifiable, Codable {
    let id: String
    var displayName: String
    var thresholds: BioThresholds
    var lastActive: Date?

    struct BioThresholds: Codable {
        var hrResting: Double = 65
        var hrMax: Double = 180
        var spo2Floor: Double = 94
        var tempBaseline: Double = 36.5
        var kTarget: ClosedRange<Double> = 3.5...5.0
        var mgTarget: ClosedRange<Double> = 1.7...2.2
        var stepsGoal: Int = 10000

        // encode range manually since ClosedRange isn't Codable by default
        enum CodingKeys: String, CodingKey {
            case hrResting, hrMax, spo2Floor, tempBaseline, stepsGoal
            case kLow, kHigh, mgLow, mgHigh
        }
        init() {}
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            hrResting = try c.decode(Double.self, forKey: .hrResting)
            hrMax = try c.decode(Double.self, forKey: .hrMax)
            spo2Floor = try c.decode(Double.self, forKey: .spo2Floor)
            tempBaseline = try c.decode(Double.self, forKey: .tempBaseline)
            stepsGoal = try c.decode(Int.self, forKey: .stepsGoal)
            let kl = try c.decode(Double.self, forKey: .kLow)
            let kh = try c.decode(Double.self, forKey: .kHigh)
            kTarget = kl...kh
            let ml = try c.decode(Double.self, forKey: .mgLow)
            let mh = try c.decode(Double.self, forKey: .mgHigh)
            mgTarget = ml...mh
        }
        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(hrResting, forKey: .hrResting)
            try c.encode(hrMax, forKey: .hrMax)
            try c.encode(spo2Floor, forKey: .spo2Floor)
            try c.encode(tempBaseline, forKey: .tempBaseline)
            try c.encode(stepsGoal, forKey: .stepsGoal)
            try c.encode(kTarget.lowerBound, forKey: .kLow)
            try c.encode(kTarget.upperBound, forKey: .kHigh)
            try c.encode(mgTarget.lowerBound, forKey: .mgLow)
            try c.encode(mgTarget.upperBound, forKey: .mgHigh)
        }
    }
}

class FamilyUnit: ObservableObject {
    @Published var wearers: [WearerProfile] = []
    @Published var activeWearer: WearerProfile?

    private let storageKey = "wearshield_family"

    init() { load() }

    func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([WearerProfile].self, from: data) {
            wearers = saved
        }
        if wearers.isEmpty { seedFromConfig() }

        let lastId = UserDefaults.standard.string(forKey: "wearshield_active_wearer")
        activeWearer = wearers.first { $0.id == lastId } ?? wearers.first
    }

    func seedFromConfig() {
        let raw = Bundle.main.object(forInfoDictionaryKey: "FAMILY_WEARERS") as? String ?? "user"
        let ids = raw.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        wearers = ids.map { id in
            WearerProfile(id: id, displayName: id.capitalized, thresholds: .init())
        }
        save()
    }

    func switchTo(_ wearer: WearerProfile) {
        var updated = wearer
        updated.lastActive = Date()
        if let idx = wearers.firstIndex(where: { $0.id == wearer.id }) {
            wearers[idx] = updated
        }
        activeWearer = updated
        UserDefaults.standard.set(wearer.id, forKey: "wearshield_active_wearer")
        save()
    }

    func addWearer(id: String, name: String) {
        guard !wearers.contains(where: { $0.id == id }) else { return }
        let profile = WearerProfile(id: id, displayName: name, thresholds: .init())
        wearers.append(profile)
        save()
    }

    func removeWearer(id: String) {
        wearers.removeAll { $0.id == id }
        if activeWearer?.id == id { activeWearer = wearers.first }
        save()
    }

    func updateThresholds(for id: String, _ update: (inout WearerProfile.BioThresholds) -> Void) {
        guard let idx = wearers.firstIndex(where: { $0.id == id }) else { return }
        update(&wearers[idx].thresholds)
        if activeWearer?.id == id { activeWearer = wearers[idx] }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(wearers) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
