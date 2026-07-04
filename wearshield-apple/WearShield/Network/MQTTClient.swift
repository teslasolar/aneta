// MQTTClient — minimal MQTT 3.1.1 over TCP
// Matches Android wearshield MqttMini — no library dependency

import Foundation
import Network

class MQTTClient: ObservableObject {
    @Published var connected = false

    private var connection: NWConnection?
    private var host: String = ""
    private var port: Int = 1883
    private var clientId: String = ""
    private var keepAliveTimer: Timer?
    private var onMessage: ((String, Data) -> Void)?

    func connect(host: String, port: Int = 1883, clientId: String? = nil, onMessage: ((String, Data) -> Void)? = nil) {
        self.host = host
        self.port = port
        self.clientId = clientId ?? "ws-apple-\(Int.random(in: 1000...9999))"
        self.onMessage = onMessage

        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: UInt16(port))!)
        connection = NWConnection(to: endpoint, using: .tcp)

        connection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.sendConnect()
            case .failed, .cancelled:
                DispatchQueue.main.async { self?.connected = false }
            default: break
            }
        }
        connection?.start(queue: .global(qos: .utility))
    }

    private func sendConnect() {
        var packet = Data()
        // fixed header: CONNECT
        packet.append(0x10)
        let clientIdBytes = Array(clientId.utf8)
        let remainLen = 10 + 2 + clientIdBytes.count
        packet.append(UInt8(remainLen))
        // protocol name "MQTT"
        packet.append(contentsOf: [0x00, 0x04, 0x4D, 0x51, 0x54, 0x54])
        // protocol level 4 (3.1.1)
        packet.append(0x04)
        // connect flags: clean session
        packet.append(0x02)
        // keep alive 25s
        packet.append(contentsOf: [0x00, 0x19])
        // client id
        packet.append(UInt8(clientIdBytes.count >> 8))
        packet.append(UInt8(clientIdBytes.count & 0xFF))
        packet.append(contentsOf: clientIdBytes)

        connection?.send(content: packet, completion: .contentProcessed { [weak self] error in
            if error == nil {
                DispatchQueue.main.async { self?.connected = true }
                self?.startKeepAlive()
                self?.receiveLoop()
            }
        })
    }

    func publish(topic: String, payload: Data, qos: UInt8 = 0) {
        guard connected else { return }
        let topicBytes = Array(topic.utf8)
        var packet = Data()
        packet.append(0x30 | (qos << 1))
        let remainLen = 2 + topicBytes.count + payload.count
        encodeLength(remainLen, into: &packet)
        packet.append(UInt8(topicBytes.count >> 8))
        packet.append(UInt8(topicBytes.count & 0xFF))
        packet.append(contentsOf: topicBytes)
        packet.append(payload)
        connection?.send(content: packet, completion: .contentProcessed { _ in })
    }

    func publish(topic: String, string: String) {
        publish(topic: topic, payload: Data(string.utf8))
    }

    func subscribe(topic: String) {
        guard connected else { return }
        let topicBytes = Array(topic.utf8)
        var packet = Data()
        packet.append(0x82)
        let remainLen = 2 + 2 + topicBytes.count + 1
        packet.append(UInt8(remainLen))
        // packet id
        packet.append(contentsOf: [0x00, 0x01])
        packet.append(UInt8(topicBytes.count >> 8))
        packet.append(UInt8(topicBytes.count & 0xFF))
        packet.append(contentsOf: topicBytes)
        packet.append(0x00) // qos 0
        connection?.send(content: packet, completion: .contentProcessed { _ in })
    }

    private func receiveLoop() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, _, error in
            if let data = data, !data.isEmpty {
                self?.parsePacket(data)
            }
            if error == nil { self?.receiveLoop() }
        }
    }

    private func parsePacket(_ data: Data) {
        guard data.count > 1 else { return }
        let type = data[0] >> 4
        if type == 3 { // PUBLISH
            guard data.count > 4 else { return }
            let topicLen = Int(data[2]) << 8 | Int(data[3])
            guard data.count > 4 + topicLen else { return }
            let topic = String(data: data[4..<(4 + topicLen)], encoding: .utf8) ?? ""
            let payload = data[(4 + topicLen)...]
            onMessage?(topic, Data(payload))
        }
    }

    private func startKeepAlive() {
        keepAliveTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
            self?.connection?.send(content: Data([0xC0, 0x00]), completion: .contentProcessed { _ in })
        }
    }

    private func encodeLength(_ length: Int, into data: inout Data) {
        var l = length
        repeat {
            var byte = UInt8(l % 128)
            l /= 128
            if l > 0 { byte |= 0x80 }
            data.append(byte)
        } while l > 0
    }

    func disconnect() {
        keepAliveTimer?.invalidate()
        connection?.send(content: Data([0xE0, 0x00]), completion: .contentProcessed { [weak self] _ in
            self?.connection?.cancel()
        })
        DispatchQueue.main.async { self.connected = false }
    }
}
