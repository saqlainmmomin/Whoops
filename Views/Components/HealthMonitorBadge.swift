import SwiftUI

struct HealthMonitorBadge: View {
    let metricsInRange: Int
    let totalMetrics: Int
    let flaggedMetrics: [String]

    private var isAllGood: Bool { metricsInRange == totalMetrics }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: isAllGood ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .foregroundStyle(isAllGood ? Theme.Colors.recoveryPeak : Theme.Colors.recoveryLow)

                Text("\(metricsInRange)/\(totalMetrics) METRICS WITHIN RANGE")
                    .font(Theme.Fonts.label(12))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .tracking(1)
                Spacer()
            }

            if !flaggedMetrics.isEmpty {
                Text("Flagged: \(flaggedMetrics.joined(separator: ", "))")
                    .font(Theme.Fonts.label(11))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.Colors.surfaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Theme.Colors.borderSubtle, lineWidth: 1)
                )
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        HealthMonitorBadge(metricsInRange: 5, totalMetrics: 5, flaggedMetrics: [])
        HealthMonitorBadge(metricsInRange: 3, totalMetrics: 5, flaggedMetrics: ["HRV", "Sleep"])
        HealthMonitorBadge(metricsInRange: 1, totalMetrics: 5, flaggedMetrics: ["HRV", "RHR", "Sleep", "Strain"])
    }
    .preferredColorScheme(.dark)
    .padding()
    .background(Theme.Colors.void)
}
