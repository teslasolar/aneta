// BLEBeacon — advertise as megazord fleet node
// Matches Android wearshield BeaconAdvertiser

import Foundation
import CoreBluetooth

class BLEBeacon: NSObject, ObservableObject, CBPeripheralManagerDelegate {
    @Published var advertising = false

    private var manager: CBPeripheralManager?
    private let config = WatchConfig.shared

    func start() {
        manager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard peripheral.state == .poweredOn else { return }

        let data: [String: Any] = [
            CBAdvertisementDataLocalNameKey: "WS-\(config.wearer.prefix(4))",
            CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: "A550")]
        ]
        peripheral.startAdvertising(data)
        DispatchQueue.main.async { self.advertising = true }
    }

    func stop() {
        manager?.stopAdvertising()
        advertising = false
    }
}
