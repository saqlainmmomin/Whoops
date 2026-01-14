import SwiftUI

struct RecoveryCard: View {
    let score: RecoveryScore?
    let trend: TrendDirection?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "arrow.up.heart.fill")
                    .foregroundColor(scoreColor)
                Text("Recovery")
                    .font(.headline)

                Spacer()

                ConfidenceIndicator(confidence: score?.confidence ?? .low)
            }

            // Main score
            HStack(alignment: .center, spacing: 20) {
                // Gauge
                MetricGauge(
                    value: Double(score?.score ?? 0),
                    maxValue: 100,
                    color: scoreColor,
                    size: 100
                )

                VStack(alignment: .leading, spacing: 8) {
                    // Score value
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(score?.score ?? 0)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))

                        Text("%")
                            .font(.title3)
                            .foregroundColor(.secondary)

                        if let trend = trend {
                            TrendIndicator(direction: trend)
                        }
                    }

                    // Category
                    Text(score?.category.rawValue ?? "No Data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Description
                    Text(score?.category.description ?? "Insufficient data to calculate recovery")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            // Component breakdown (mini)
            if let score = score {
                componentBreakdown(score)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    // MARK: - Component Breakdown

    private func componentBreakdown(_ score: RecoveryScore) -> some View {
        VStack(spacing: 8) {
            Divider()

            HStack(spacing: 12) {
                componentPill("HRV", value: score.hrvComponent.normalizedValue)
                componentPill("RHR", value: score.rhrComponent.normalizedValue)
                componentPill("Sleep", value: score.sleepDurationComponent.normalizedValue)
            }
        }
    }

    private func componentPill(_ label: String, value: Double) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text("\(Int(value))")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(componentColor(for: value))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    // MARK: - Colors

    private var scoreColor: Color {
        guard let score = score?.score else { return .gray }
        switch score {
        case 0...33: return .red
        case 34...66: return .yellow
        default: return .green
        }
    }

    private func componentColor(for value: Double) -> Color {
        switch value {
        case 0...33: return .red
        case 34...66: return .orange
        default: return .green
        }
    }
}

#Preview {
    VStack {
        RecoveryCard(
            score: RecoveryScore(
                score: 72,
                confidence: .high,
                hrvComponent: ScoreComponent(name: "HRV", rawValue: 1.2, normalizedValue: 80, weight: 0.4, contribution: 32),
                rhrComponent: ScoreComponent(name: "RHR", rawValue: -3, normalizedValue: 65, weight: 0.2, contribution: 13),
                sleepDurationComponent: ScoreComponent(name: "Sleep", rawValue: 95, normalizedValue: 70, weight: 0.25, contribution: 17.5),
                sleepInterruptionComponent: ScoreComponent(name: "Interruptions", rawValue: 2, normalizedValue: 60, weight: 0.15, contribution: 9)
            ),
            trend: .improving
        )

        RecoveryCard(score: nil, trend: nil)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
