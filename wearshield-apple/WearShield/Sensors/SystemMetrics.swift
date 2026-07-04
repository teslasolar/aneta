// SystemMetrics — battery, thermal state, device info

import Foundation
import WatchKit

class SystemMetrics: ObservableObject {
    @Published var batteryPct: Float = 1.0
    @Published var batteryState: String = "unknown"
    @Published var thermalState: String = "nominal"
    @Published var deviceModel: String = ""
    @Published var osVersion: String = ""

    private var timer: Timer?

    func start() {
        let device = WKInterfaceDevice.current()
        device.isBatteryMonitoringEnabled = true
        deviceModel = device.model
        osVersion = device.systemVersion

        poll()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    private func poll() {
        let device = WKInterfaceDevice.current()
        batteryPct = device.batteryLevel
        batteryState = {
            switch device.batteryState {
            case .charging: return "charging"
            case .full: return "full"
            case .unplugged: return "unplugged"
            default: return "unknown"
            }
        }()

        thermalState = {
            switch ProcessInfo.processInfo.thermalState {
            case .nominal: return "nominal"
            case .fair: return "fair"
            case .serious: return "serious"
            case .critical: return "critical"
            @unknown default: return "unknown"
            }
        }()
    }

    func stop() {
        timer?.invalidate()
    }
}
