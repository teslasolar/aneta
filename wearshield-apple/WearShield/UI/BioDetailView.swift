// BioDetailView — scrollable biomarker detail screen
// Shows all modules with values, trends, alert levels

import SwiftUI

struct BioDetailView: View {
    @EnvironmentObject var bloom: BloomState

    private let alertColors: [Color] = [.green, .yellow, .orange, .red]

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                Text("BIOMARKERS")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(Color(red: 0.83, green: 0.66, blue: 0.29).opacity(0.5))
                    .tracking(2)
                    .padding(.top, 4)

                ForEach(Array(bloom.biomarkers.values).sorted(by: { $0.id < $1.id }), id: \.id) { bio in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(alertColors[min(3, bio.alertLevel)])
                            .frame(width: 6, height: 6)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(bio.name)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                            if let msg = bio.message {
                                Text(msg)
                                    .font(.system(size: 7, design: .monospaced))
                                    .foregroundColor(alertColors[min(3, bio.alertLevel)].opacity(0.7))
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 1) {
                            Text("\(bio.value, specifier: "%.1f") \(bio.unit)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(alertColors[min(3, bio.alertLevel)])
                            Text(trendArrow(bio.trend))
                                .font(.system(size: 8))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.02)))
                }

                Divider().background(Color.gray.opacity(0.1))

                HStack {
                    Text("κ=\(bloom.kappa, specifier: "%.4f")")
                    Spacer()
                    Text("φ·κ=\(PHI * bloom.kappa, specifier: "%.4f")")
                }
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.gray.opacity(0.3))
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }
        }
        .background(Color.black)
    }

    func trendArrow(_ trend: Double) -> String {
        if trend > 0.05 { return "↑" }
        if trend < -0.05 { return "↓" }
        return "→"
    }
}
