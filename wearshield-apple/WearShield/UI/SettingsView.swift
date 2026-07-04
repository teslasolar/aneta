// SettingsView — wearer thresholds, gateway config, system info

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var family: FamilyUnit
    @EnvironmentObject var gateway: GatewayClient
    @EnvironmentObject var bloom: BloomState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("SETTINGS")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(Color(red: 0.83, green: 0.66, blue: 0.29).opacity(0.5))
                    .tracking(2)
                    .padding(.top, 4)

                if let w = family.activeWearer {
                    Group {
                        sectionTitle("WEARER: \(w.displayName)")
                        infoRow("HR resting", "\(Int(w.thresholds.hrResting)) bpm")
                        infoRow("HR max", "\(Int(w.thresholds.hrMax)) bpm")
                        infoRow("SpO2 floor", "\(Int(w.thresholds.spo2Floor))%")
                        infoRow("Temp baseline", "\(w.thresholds.tempBaseline, specifier: "%.1f")°C")
                        infoRow("K+ target", "\(w.thresholds.kTarget.lowerBound, specifier: "%.1f")-\(w.thresholds.kTarget.upperBound, specifier: "%.1f") mEq/L")
                        infoRow("Mg target", "\(w.thresholds.mgTarget.lowerBound, specifier: "%.1f")-\(w.thresholds.mgTarget.upperBound, specifier: "%.1f") mg/dL")
                        infoRow("Steps goal", "\(w.thresholds.stepsGoal)")
                    }
                }

                sectionTitle("GATEWAY")
                infoRow("Status", gateway.connected ? "connected" : "standalone")
                infoRow("Discovery", WatchConfig.shared.isAutoDiscovery ? "AUTO (Bonjour)" : "STATIC")

                sectionTitle("SYSTEM")
                infoRow("Model", WatchConfig.shared.watchModel)
                infoRow("ECG", WatchConfig.shared.hasECG ? "YES" : "NO")
                infoRow("SpO2", WatchConfig.shared.hasBloodOxygen ? "YES" : "NO")
                infoRow("Skin temp", WatchConfig.shared.hasSkinTemp ? "YES" : "NO")

                sectionTitle("FOLD")
                infoRow("κ*", "1/φ = \(KappaDynamics.kStar, specifier: "%.6f")")
                infoRow("α", "\(KappaDynamics.alpha, specifier: "%.3f")")
                infoRow("β", "\(KappaDynamics.beta, specifier: "%.4f")")
                infoRow("γ", "\(KappaDynamics.gamma, specifier: "%.4f")")
                infoRow("Modules", "\(bloom.biomarkers.count)")
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 12)
        }
        .background(Color.black)
    }

    func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8, design: .monospaced))
            .foregroundColor(.red.opacity(0.4))
            .tracking(1.5)
            .padding(.top, 6)
    }

    func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundColor(.gray.opacity(0.4))
            Spacer()
            Text(value).foregroundColor(.white.opacity(0.6))
        }
        .font(.system(size: 9, design: .monospaced))
    }
}
