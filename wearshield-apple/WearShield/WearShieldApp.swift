// WearShield — Apple Watch entry point
// Runs standalone (no gateway needed) or syncs when one is found
// Generalized for any user / family unit via Config.xcconfig

import SwiftUI
import HealthKit

@main
struct WearShieldApp: App {
    @StateObject private var family = FamilyUnit()
    @StateObject private var sensorHub = SensorHub()
    @StateObject private var gateway = GatewayClient()
    @StateObject private var discovery = GatewayDiscovery()
    @StateObject private var bloomState = BloomState()
    @State private var showPicker = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                ShieldView()
                    .environmentObject(sensorHub)
                    .environmentObject(gateway)
                    .environmentObject(bloomState)
                    .environmentObject(family)
                    .onAppear { boot() }
                    .onLongPressGesture(minimumDuration: 1) { showPicker = true }

                if showPicker || family.activeWearer == nil {
                    WearerPicker(isPresented: $showPicker)
                        .environmentObject(family)
                        .transition(.move(edge: .bottom))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showPicker)
            .onChange(of: family.activeWearer?.id) { _ in onWearerSwitch() }
        }
    }

    private func boot() {
        if family.activeWearer == nil { showPicker = true; return }
        sensorHub.start()
        // gateway is optional — bloom runs standalone, syncs when gateway found
        if discovery.discovered.isEmpty && !WatchConfig.shared.isAutoDiscovery {
            gateway.connect(wearer: family.activeWearer?.id ?? "user",
                           host: discovery.activeHost, port: discovery.activePort)
        }
        // link with gateway as optional (nil if not connected)
        bloomState.link(sensors: sensorHub, gateway: gateway.connected ? gateway : nil)

        // if auto-discovery, watch for gateway appearance
        if WatchConfig.shared.isAutoDiscovery {
            Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [self] _ in
                if !gateway.connected && !discovery.discovered.isEmpty {
                    gateway.connect(wearer: family.activeWearer?.id ?? "user",
                                   host: discovery.activeHost, port: discovery.activePort)
                    bloomState.link(sensors: sensorHub, gateway: gateway)
                }
            }
        }
    }

    private func onWearerSwitch() {
        guard let w = family.activeWearer else { return }
        if gateway.connected {
            gateway.disconnect()
            gateway.connect(wearer: w.id, host: discovery.activeHost, port: discovery.activePort)
        }
        bloomState.resetForWearer(w)
    }
}
