import SwiftUI

// MARK: - Brutalist Block
// Sharp edges. Visible borders. Industrial hierarchy.

struct DeepDataCard<Content: View>: View {
    let title: String
    let value: String
    let subtitle: String?
    let accent: Color
    let trend: TrendDirection?
    @ViewBuilder let content: Content

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        accent: Color = Theme.Colors.bone,
        trend: TrendDirection? = nil,
        @ViewBuilder content: () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.accent = accent
        self.trend = trend
        self.content = content()
    }

    private var hasCriticalTrend: Bool {
        trend == .declining
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header row - label + trend
            HStack(alignment: .center) {
                Text(title.uppercased())
                    .font(Theme.Fonts.label(size: 10))
                    .foregroundColor(Theme.Colors.chalk)
                    .tracking(2)

                Spacer()

                if let trend = trend {
                    trendBadge(trend)
                }
            }

            // Divider line
            Rectangle()
                .fill(Theme.Colors.graphite)
                .frame(height: 1)

            // Main value - massive, dominant
            HStack(alignment: .lastTextBaseline, spacing: Theme.Spacing.xs) {
                Text(value)
                    .font(Theme.Fonts.display(size: 32))
                    .foregroundColor(hasCriticalTrend ? Theme.Colors.rust : Theme.Colors.bone)
                    .monospacedDigit()

                if let subtitle = subtitle {
                    Text(subtitle.uppercased())
                        .font(Theme.Fonts.label(size: 11))
                        .foregroundColor(Theme.Colors.chalk)
                        .tracking(1)
                }
            }

            // Custom content (sparklines, etc.)
            content
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.concrete)
        .brutalistBorder(hasCriticalTrend ? Theme.Colors.rust : Theme.Colors.graphite)
    }

    @ViewBuilder
    private func trendBadge(_ trend: TrendDirection) -> some View {
        HStack(spacing: 2) {
            Image(systemName: trend.icon)
                .font(.system(size: 9, weight: .bold))

            Text(trendText(trend))
                .font(Theme.Fonts.mono(size: 9))
                .tracking(1)
        }
        .foregroundColor(trendColor(trend))
    }

    private func trendText(_ trend: TrendDirection) -> String {
        switch trend {
        case .improving: return "UP"
        case .stable: return "—"
        case .declining: return "DOWN"
        }
    }

    private func trendColor(_ trend: TrendDirection) -> Color {
        switch trend {
        case .improving: return Theme.Colors.bone
        case .stable: return Theme.Colors.ash
        case .declining: return Theme.Colors.rust
        }
    }
}

// MARK: - Minimal Variant (for dense grids)

struct BrutalistDataCell: View {
    let label: String
    let value: String
    let unit: String?
    var isCritical: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(label.uppercased())
                .font(Theme.Fonts.label(size: 9))
                .foregroundColor(Theme.Colors.ash)
                .tracking(2)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(Theme.Fonts.mono(size: 20))
                    .foregroundColor(isCritical ? Theme.Colors.rust : Theme.Colors.bone)
                    .monospacedDigit()

                if let unit = unit {
                    Text(unit.uppercased())
                        .font(Theme.Fonts.label(size: 9))
                        .foregroundColor(Theme.Colors.chalk)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.steel)
        .brutalistBorder()
    }
}

#Preview {
    ZStack {
        Theme.Colors.void.ignoresSafeArea()

        VStack(spacing: Theme.Spacing.md) {
            DeepDataCard(
                title: "Heart Rate Variability",
                value: "42",
                subtitle: "ms",
                trend: .improving
            )

            DeepDataCard(
                title: "Resting Heart Rate",
                value: "72",
                subtitle: "bpm",
                trend: .declining
            )

            HStack(spacing: Theme.Spacing.sm) {
                BrutalistDataCell(label: "Steps", value: "8,432", unit: nil)
                BrutalistDataCell(label: "Calories", value: "2,180", unit: "kcal", isCritical: true)
            }
        }
        .padding()
    }
}
