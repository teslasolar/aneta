// ShieldView — main watch UI with bloom ring visualization
// Matches Android wearshield UnifiedShieldScreen

import SwiftUI

struct ShieldView: View {
    @EnvironmentObject var sensors: SensorHub
    @EnvironmentObject var gateway: GatewayClient
    @EnvironmentObject var bloom: BloomState

    @EnvironmentObject var family: FamilyUnit

    private func bioDotsView(bios: [BioReading]) -> some View {
        let count = bios.count
        return Canvas { ctx, size in
            let cx = size.width / 2, cy = size.height / 2, r = min(cx, cy) * 0.55
            for (i, bio) in bios.enumerated() {
                let ang = Double(i) / Double(count) * .pi * 2 - .pi / 2
                let x = cx + cos(ang) * r, y = cy + sin(ang) * r
                let color = alertColor(bio.alertLevel)
                ctx.fill(Path(ellipseIn: CGRect(x: x - 3, y: y - 3, width: 6, height: 6)),
                         with: .color(color.opacity(0.7)))
            }
        }
        .frame(height: 30)
    }

    private func bioChip(_ label: String, _ reading: BioReading) -> some View {
        VStack(spacing: 0) {
            Text(label).font(.system(size: 6, design: .monospaced))
                .foregroundColor(alertColor(reading.alertLevel).opacity(0.5))
            Text("\(reading.value, specifier: "%.1f")")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(alertColor(reading.alertLevel))
        }
    }

    private func alertColor(_ level: Int) -> Color {
        switch level {
        case 0: return .green
        case 1: return .yellow
        case 2: return .orange
        default: return .red
        }
    }

    private let ringColors: [Color] = [
        Color(red: 0.6, green: 0.2, blue: 0.4),
        Color(red: 0, green: 0.67, blue: 0.87),
        Color(red: 1, green: 0.67, blue: 0),
        Color(red: 1, green: 0.27, blue: 0.27),
        Color(red: 0.27, green: 0.67, blue: 0.27),
        Color(red: 0.67, green: 0.27, blue: 1),
        Color(red: 0.8, green: 0.8, blue: 0.8)
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Canvas { ctx, size in
                let cx = size.width / 2, cy = size.height / 2
                let maxR = min(cx, cy) * 0.85

                // 7 bloom rings
                for i in 0..<7 {
                    let r = maxR * (0.25 + Double(i) * 0.1)
                    let opacity = 0.15 + bloom.bloom[i] * 0.12
                    let width = 1.0 + bloom.bloom[i] * 0.5
                    ctx.stroke(
                        Path { p in p.addArc(center: CGPoint(x: cx, y: cy), radius: r, startAngle: .zero, endAngle: .degrees(360), clockwise: false) },
                        with: .color(ringColors[i].opacity(opacity)),
                        lineWidth: width
                    )

                    // prime segment markers
                    let segs = [2, 3, 5, 7, 11, 13, 17][i]
                    let lit = Int(round(bloom.bloom[i])) % segs
                    for s in 0..<segs {
                        let ang = Double(s) / Double(segs) * .pi * 2 - .pi / 2
                        let px = cx + cos(ang) * r, py = cy + sin(ang) * r
                        let dotR: CGFloat = s == lit ? 3 : 1.5
                        let dotOp = s == lit ? 0.8 : 0.2
                        ctx.fill(Path(ellipseIn: CGRect(x: px - dotR, y: py - dotR, width: dotR * 2, height: dotR * 2)),
                                 with: .color(ringColors[i].opacity(dotOp)))
                    }
                }

                // center κ orb
                let orbR: CGFloat = 12 + bloom.emergence * 8
                let orbColor = bloom.kappa > 0.6 ? Color(red: 0.83, green: 0.66, blue: 0.29) : Color(red: 0.86, green: 0.08, blue: 0.24)
                ctx.fill(Path(ellipseIn: CGRect(x: cx - orbR, y: cy - orbR, width: orbR * 2, height: orbR * 2)),
                         with: .color(orbColor.opacity(0.4)))
            }

            VStack(spacing: 2) {
                HStack {
                    Text("κ=\(bloom.kappa, specifier: "%.3f")")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.red.opacity(0.5))
                    Spacer()
                    if let w = family.activeWearer {
                        Text(w.displayName)
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                    Circle()
                        .fill(gateway.connected ? Color.green : Color.orange)
                        .frame(width: 4, height: 4)
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)

                Spacer()

                // biomarker dots ring
                let bios = Array(bloom.biomarkers.values).sorted(by: { $0.id < $1.id })
                if !bios.isEmpty {
                    bioDotsView(bios: bios)
                }

                Text("\(Int(sensors.heartRate))")
                    .font(.system(size: 24, weight: .light, design: .monospaced))
                    .foregroundColor(.red.opacity(0.8))

                // crash risk if available
                if let cra = bloom.biomarkers["CRA"] {
                    Text("\(Int(cra.value * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(alertColor(cra.alertLevel))
                    if let msg = cra.message {
                        Text(msg)
                            .font(.system(size: 7, design: .monospaced))
                            .foregroundColor(alertColor(cra.alertLevel).opacity(0.7))
                    }
                }

                Text(bloom.shield)
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundColor(.red.opacity(0.25))

                Spacer()

                HStack {
                    // key electrolytes
                    if let k = bloom.biomarkers["K"] {
                        bioChip("K", k)
                    }
                    if let mg = bloom.biomarkers["Mg"] {
                        bioChip("Mg", mg)
                    }
                    if let hyd = bloom.biomarkers["Hyd"] {
                        bioChip("H₂O", hyd)
                    }
                    Spacer()
                    Text("\(Int(sensors.batteryLevel * 100))%")
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.3))
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            }
        }
    }
}
