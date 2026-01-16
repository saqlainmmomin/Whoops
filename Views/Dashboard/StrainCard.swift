import SwiftUI

// MARK: - Brutalist Strain Card
// Raw. Industrial. High contrast.

struct StrainCard: View {
    let score: StrainScore?
    let trend: TrendDirection?

    private var isCritical: Bool {
        (score?.score ?? 0) >= 67
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header row
            HStack(alignment: .center) {
                Text("STRAIN")
                    .font(Theme.Fonts.label(size: 10))
                    .foregroundColor(Theme.Colors.chalk)
                    .tracking(2)

                Spacer()

                ConfidenceIndicator(confidence: score?.confidence ?? .low, compact: true)
            }

            // Score row
            HStack(alignment: .center, spacing: Theme.Spacing.md) {
                // Score value
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(score?.score ?? 0)")
                        .font(Theme.Fonts.display(size: 36))
                        .foregroundColor(scoreColor)
                        .monospacedDigit()

                    if let trend = trend {
                        trendIndicator(trend)
                    }
                }

                Spacer()

                // Category
                Text((score?.category.rawValue ?? "NO DATA").uppercased())
                    .font(Theme.Fonts.mono(size: 10))
                    .foregroundColor(Theme.Colors.chalk)
                    .tracking(1)
            }

            // Progress bar - brutalist style
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Rectangle()
                        .fill(Theme.Colors.steel)

                    // Fill
                    Rectangle()
                        .fill(scoreColor)
                        .frame(width: geo.size.width * CGFloat(score?.score ?? 0) / 100)

                    // Tick marks at 33% and 67%
                    HStack(spacing: 0) {
                        Spacer()
                            .frame(width: geo.size.width * 0.33 - 1)
                        Rectangle()
                            .fill(Theme.Colors.void)
                            .frame(width: 2)
                        Spacer()
                            .frame(width: geo.size.width * 0.34 - 2)
                        Rectangle()
                            .fill(Theme.Colors.void)
                            .frame(width: 2)
                        Spacer()
                    }
                }
            }
            .frame(height: 8)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.concrete)
        .brutalistBorder(isCritical ? Theme.Colors.rust : Theme.Colors.graphite)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func trendIndicator(_ trend: TrendDirection) -> some View {
        Image(systemName: trend.icon)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(trendColor(trend))
    }

    private var scoreColor: Color {
        guard let score = score?.score else { return Theme.Colors.ash }
        return Theme.Colors.strain(score: score)
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
            StrainCard(
                score: StrainScore(
                    score: 45,
                    confidence: .medium,
                    zoneComponent: ScoreComponent(name: "Zone", rawValue: 35, normalizedValue: 50, weight: 0.5, contribution: 25),
                    durationComponent: ScoreComponent(name: "Duration", rawValue: 30, normalizedValue: 50, weight: 0.3, contribution: 15),
                    energyComponent: ScoreComponent(name: "Energy", rawValue: 110, normalizedValue: 55, weight: 0.2, contribution: 11)
                ),
                trend: .stable
            )

            StrainCard(
                score: StrainScore(
                    score: 82,
                    confidence: .high,
                    zoneComponent: ScoreComponent(name: "Zone", rawValue: 65, normalizedValue: 85, weight: 0.5, contribution: 42.5),
                    durationComponent: ScoreComponent(name: "Duration", rawValue: 60, normalizedValue: 80, weight: 0.3, contribution: 24),
                    energyComponent: ScoreComponent(name: "Energy", rawValue: 350, normalizedValue: 78, weight: 0.2, contribution: 15.6)
                ),
                trend: .improving
            )

            StrainCard(score: nil, trend: nil)
        }
        .padding()
    }
}
