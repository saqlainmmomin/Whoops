import SwiftUI

/// Gap S-10/R-8/ST-5: Reusable chart card header with icon + uppercase title + chevron
/// Matches WHOOP design pattern for all chart cards across Sleep, Recovery, and Strain tabs
struct ChartCardHeader: View {
    let icon: String
    let title: String
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textSecondary)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .tracking(0.5)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.textTertiary)
            }
        }
        .disabled(onTap == nil)
    }
}

#Preview {
    VStack(spacing: 16) {
        ChartCardHeader(icon: "moon.fill", title: "SLEEP PERFORMANCE")
        ChartCardHeader(icon: "waveform.path.ecg", title: "HEART RATE VARIABILITY")
        ChartCardHeader(icon: "heart.fill", title: "RESTING HEART RATE")
        ChartCardHeader(icon: "bolt.fill", title: "STRAIN")
        ChartCardHeader(icon: "flame.fill", title: "CALORIES")
    }
    .padding()
    .background(Theme.Colors.primary)
}
