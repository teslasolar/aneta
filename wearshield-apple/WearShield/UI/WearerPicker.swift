// WearerPicker — family member selection on watch
// Shows on first launch or long-press, switches active wearer

import SwiftUI

struct WearerPicker: View {
    @EnvironmentObject var family: FamilyUnit
    @Binding var isPresented: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("WHO'S WEARING?")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color(red: 0.83, green: 0.66, blue: 0.29).opacity(0.6))
                    .tracking(2)
                    .padding(.top, 8)

                ForEach(family.wearers) { wearer in
                    Button {
                        family.switchTo(wearer)
                        isPresented = false
                    } label: {
                        HStack {
                            Circle()
                                .fill(wearer.id == family.activeWearer?.id ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                            Text(wearer.displayName)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(.white)
                            Spacer()
                            if let last = wearer.lastActive {
                                Text(timeAgo(last))
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundColor(.gray.opacity(0.4))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(wearer.id == family.activeWearer?.id ?
                                      Color(red: 0.86, green: 0.08, blue: 0.24).opacity(0.15) :
                                      Color.white.opacity(0.03))
                        )
                    }
                    .buttonStyle(.plain)
                }

                Divider().background(Color.gray.opacity(0.1)).padding(.vertical, 4)

                Text("κ=1/φ · φ·κ=1")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.2))
            }
            .padding(.horizontal, 8)
        }
        .background(Color.black)
    }

    func timeAgo(_ date: Date) -> String {
        let mins = Int(-date.timeIntervalSinceNow / 60)
        if mins < 1 { return "now" }
        if mins < 60 { return "\(mins)m" }
        let hrs = mins / 60
        if hrs < 24 { return "\(hrs)h" }
        return "\(hrs / 24)d"
    }
}
