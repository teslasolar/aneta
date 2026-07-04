// GatewayClient — HTTP + MQTT transport to ASS-OS gateway
// Mirrors Android wearshield BlossomClient + MqttMini

import Foundation
import Combine

class GatewayClient: ObservableObject {
    @Published var connected = false
    @Published var lastResponse: String = ""
    @Published var activeWearer: String = "user"

    private var host: String = "10.0.0.25"
    private var port: Int = 5540
    private var pollTimer: Timer?
    private let session = URLSession(configuration: .ephemeral)

    func connect(wearer: String = "user", host: String? = nil, port: Int? = nil) {
        let config = WatchConfig.shared
        self.activeWearer = wearer
        self.host = host ?? config.gatewayHost
        self.port = port ?? config.gatewayPort
        pollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.poll()
        }
        poll()
    }

    func poll() {
        blossomCall(method: "bloomwatch.state", params: ["user_id": activeWearer]) { [weak self] data in
            DispatchQueue.main.async {
                self?.connected = data != nil
                if let d = data, let s = String(data: d, encoding: .utf8) { self?.lastResponse = s }
            }
        }
    }

    func sendSample(bloom: [Double], kappa: Double, battery: Float) {
        let params: [String: Any] = [
            "user_id": activeWearer,
            "bloom": bloom.map { round($0 * 100) / 100 },
            "kappa": round(kappa * 10000) / 10000,
            "battery_pct": Int(battery * 100),
            "platform": "apple_watch",
            "model": WatchConfig.shared.watchModel
        ]
        blossomCall(method: "bloomwatch.sample", params: params)
    }

    func sendBattery(pct: Int, currentUA: Int) {
        blossomCall(method: "bloomwatch.battery", params: [
            "user_id": activeWearer, "pct": pct, "current_ua": currentUA
        ])
    }

    private func blossomCall(method: String, params: [String: Any], completion: ((Data?) -> Void)? = nil) {
        guard let paramsJSON = try? JSONSerialization.data(withJSONObject: params),
              let paramsStr = String(data: paramsJSON, encoding: .utf8) else { return }

        let baseURL = URL(string: "http://\(host):\(port)/blossom/call")!
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "method", value: method),
            URLQueryItem(name: "params", value: paramsStr)
        ]
        guard let url = components.url else { return }

        var request = URLRequest(url: url, timeoutInterval: 5)
        request.httpMethod = "POST"

        session.dataTask(with: request) { data, response, error in
            completion?(error == nil ? data : nil)
        }.resume()
    }

    func disconnect() {
        pollTimer?.invalidate()
        pollTimer = nil
        connected = false
    }
}
