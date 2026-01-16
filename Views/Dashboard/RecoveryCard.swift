import SwiftUI

// MARK: - Brutalist Recovery Card
// Stark. Data-forward. Industrial.

struct RecoveryCard: View {
    let score: RecoveryScore?
    let trend: TrendDirection?

    private var isCritical: Bool {
        (score?.score ?? 0) <= 33
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header row
            HStack(alignment: .center) {
                Text("RECOVERY")
                    .font(Theme.Fonts.label(size: 10))
                    .foregroundColor(Theme.Colors.chalk)
                    .tracking(2)

                Spacer()

                ConfidenceIndicator(confidence: score?.confidence ?? .low)
            }

            // Divider
            Rectangle()
                .fill(Theme.Colors.graphite)
                .frame(height: 1)

            // Main score display
            HStack(alignment: .center, spacing: Theme.Spacing.lg) {
                // Score bar
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Theme.Colors.steel)
                            Rectangle()
                                .fill(scoreColor)
                                .frame(width: geo.size.width * CGFloat(score?.score ?? 0) / 100)
                        }
                    }
                    .frame(height: 12)

                    // Category
                    Text((score?.category.rawValue ?? "NO DATA").uppercased())
                        .font(Theme.Fonts.mono(size: 11))
                        .foregroundColor(Theme.Colors.chalk)
                        .tracking(1)
                }

                Spacer()

                // Score value
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(score?.score ?? 0)")
                        .font(Theme.Fonts.display(size: 48))
                        .foregroundColor(scoreColor)
                        .monospacedDigit()

                    Text("%")
                        .font(Theme.Fonts.mono(size: 18))
                        .foregroundColor(Theme.Colors.chalk)

                    if let trend = trend {
                        trendIndicator(trend)
                            .padding(.leading, Theme.Spacing.xs)
                    }
                }
            }

            // Component breakdown
            if let score = score {
                componentBreakdown(score)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.concrete)
        .brutalistBorder(isCritical ? Theme.Colors.rust : Theme.Colors.graphite)
    }

    // MARK: - Components

    private func componentBreakdown(_ score: RecoveryScore) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Rectangle()
                .fill(Theme.Colors.graphite)
                .frame(height: 1)

            HStack(spacing: Theme.Spacing.sm) {
                componentCell("HRV", value: Int(score.hrvComponent.normalizedValue))
                componentCell("RHR", value: Int(score.rhrComponent.normalizedValue))
                componentCell("SLEEP", value: Int(score.sleepDurationComponent.normalizedValue))
            }
        }
    }

    private func componentCell(_ label: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Theme.Fonts.label(size: 9))
                .foregroundColor(Theme.Colors.ash)
                .tracking(1)

            Text("\(value)")
                .font(Theme.Fonts.mono(size: 14))
                .foregroundColor(componentColor(value))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.xs)
        .background(Theme.Colors.steel)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func trendIndicator(_ trend: TrendDirection) -> some View {
        Image(systemName: trend.icon)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(trendColor(trend))
    }

    private var scoreColor: Color {
        guard let score = score?.score else { return Theme.Colors.ash }
        return Theme.Colors.recovery(score: score)
    }

    private func componentColor(_ value: Int) -> Color {
        value <= 33 ? Theme.Colors.rust : Theme.Colors.bone
    }

    private func trendColor(_ trend: TrendDirection) -> Color {
        switch trend {
        case .improving: return Theme.Colors.bone
        case .stable: return Theme.Colors.ash
        case .declining: return Theme.Colors.rust
        }
    }
}

#Preview {
    ZStack {
        Theme.Colors.void.ignoresSafeArea()

        VStack(spacing: Theme.Spacing.md) {
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

            RecoveryCard(
                score: RecoveryScore(
                    score: 28,
                    confidence: .medium,
                    hrvComponent: ScoreComponent(name: "HRV", rawValue: -1.5, normalizedValue: 25, weight: 0.4, contribution: 10),
                    rhrComponent: ScoreComponent(name: "RHR", rawValue: 5, normalizedValue: 30, weight: 0.2, contribution: 6),
                    sleepDurationComponent: ScoreComponent(name: "Sleep", rawValue: 60, normalizedValue: 35, weight: 0.25, contribution: 8.75),
                    sleepInterruptionComponent: ScoreComponent(name: "Interruptions", rawValue: 5, normalizedValue: 20, weight: 0.15, contribution: 3)
                ),
                trend: .declining
            )
        }
        .padding()
    }
}
