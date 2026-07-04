// GatewayDiscovery — auto-find ASS-OS gateway on LAN via Bonjour
// Falls back to static Config.xcconfig host if discovery fails

import Foundation
import Network

class GatewayDiscovery: ObservableObject {
    @Published var discovered: [(host: String, port: Int)] = []
    @Published var activeHost: String
    @Published var activePort: Int

    private var browser: NWBrowser?
    private let config = WatchConfig.shared

    init() {
        activeHost = config.gatewayHost
        activePort = config.gatewayPort
        if config.isAutoDiscovery { startBrowsing() }
    }

    func startBrowsing() {
        let params = NWParameters()
        params.includePeerToPeer = true
        browser = NWBrowser(for: .bonjour(type: "_assos._tcp", domain: nil), using: params)

        browser?.browseResultsChangedHandler = { [weak self] results, _ in
            for result in results {
                if case .service(let name, _, _, _) = result.endpoint {
                    self?.resolve(result: result, name: name)
                }
            }
        }
        browser?.start(queue: .main)

        // timeout: fall back to static after 5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            if self?.discovered.isEmpty == true {
                self?.activeHost = self?.config.gatewayHost ?? "10.0.0.25"
                self?.activePort = self?.config.gatewayPort ?? 5540
            }
        }
    }

    private func resolve(result: NWBrowser.Result, name: String) {
        let conn = NWConnection(to: result.endpoint, using: .tcp)
        conn.stateUpdateHandler = { [weak self] state in
            if case .ready = state {
                if let path = conn.currentPath,
                   let endpoint = path.remoteEndpoint,
                   case .hostPort(let host, let port) = endpoint {
                    let h = "\(host)"
                    let p = Int(port.rawValue)
                    DispatchQueue.main.async {
                        self?.discovered.append((host: h, port: p))
                        if self?.discovered.count == 1 {
                            self?.activeHost = h
                            self?.activePort = p
                        }
                    }
                }
                conn.cancel()
            }
        }
        conn.start(queue: .global())
    }

    func stop() {
        browser?.cancel()
        browser = nil
    }
}
