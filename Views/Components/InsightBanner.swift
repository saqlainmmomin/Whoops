import SwiftUI

struct Insight: Identifiable {
    let id = UUID()
    let icon: String
    let headline: String
    let detail: String
    let accentColor: Color
}

struct InsightBanner: View {
    let insight: Insight

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: insight.icon)
                .font(.system(size: 24))
                .foregroundStyle(insight.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.headline.uppercased())
                    .font(Theme.Fonts.label(11))
                    .foregroundStyle(insight.accentColor)
                    .tracking(1)

                Text(insight.detail)
                    .font(Theme.Fonts.label(13))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(insight.accentColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(insight.accentColor.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

#Preview {
    VStack(spacing: 16) {
        InsightBanner(insight: Insight(
            icon: "arrow.up.heart.fill",
            headline: "Elevated HRV",
            detail: "HRV is 15% above baseline. Good day for intensity.",
            accentColor: Theme.Colors.hrvPositive
        ))

        InsightBanner(insight: Insight(
            icon: "bolt.fill",
            headline: "Peak Recovery",
            detail: "Your body is primed for peak performance.",
            accentColor: Theme.Colors.recoveryPeak
        ))

        InsightBanner(insight: Insight(
            icon: "moon.fill",
            headline: "Sleep Deficit",
            detail: "You're 2.5 hours below your sleep target this week.",
            accentColor: Theme.Colors.sleepPoor
        ))
    }
    .preferredColorScheme(.dark)
    .padding(.vertical)
    .background(Theme.Colors.void)
}
