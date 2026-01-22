import SwiftUI

/// 2-column grid metric tile for dashboard overview
struct MetricTile: View {
    let icon: String
    let value: String
    let label: String
    let sublabel: String?
    let color: Color

    init(
        icon: String,
        value: String,
        label: String,
        sublabel: String? = nil,
        color: Color
    ) {
        self.icon = icon
        self.value = value
        self.label = label
        self.sublabel = sublabel
        self.color = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16))
                Spacer()
            }

            Text(value)
                .font(Theme.Fonts.display(28))
                .foregroundColor(Theme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label.uppercased())
                .font(Theme.Fonts.label(11))
                .tracking(0.5)
                .foregroundColor(Theme.Colors.textSecondary)

            if let sublabel {
                Text(sublabel)
                    .font(Theme.Fonts.label(10))
                    .foregroundColor(color)
            }
        }
        .padding(Theme.Spacing.cardGap)
        .background(Theme.Colors.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Tappable Metric Tile

/// Metric tile with navigation support
struct TappableMetricTile<Destination: Hashable>: View {
    let icon: String
    let value: String
    let label: String
    let sublabel: String?
    let color: Color
    let destination: Destination

    var body: some View {
        NavigationLink(value: destination) {
            MetricTile(
                icon: icon,
                value: value,
                label: label,
                sublabel: sublabel,
                color: color
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Large Metric Display

/// Large metric display for detail views
struct LargeMetricDisplay: View {
    let value: String
    let unit: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(Theme.Fonts.display(48))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(unit)
                    .font(Theme.Fonts.label(16))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Text(label.uppercased())
                .font(Theme.Fonts.label(13))
                .tracking(1)
                .foregroundColor(Theme.Colors.textSecondary)
        }
    }
}

// MARK: - Metric Row

/// Horizontal metric row for lists
struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    let valueColor: Color

    init(
        icon: String,
        label: String,
        value: String,
        valueColor: Color = Theme.Colors.textPrimary
    ) {
        self.icon = icon
        self.label = label
        self.value = value
        self.valueColor = valueColor
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Theme.Colors.textSecondary)
                .frame(width: 24)

            Text(label)
                .font(Theme.Fonts.body)
                .foregroundColor(Theme.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(Theme.Fonts.display(15))
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Comparison Metric

/// Metric with comparison to previous value
struct ComparisonMetric: View {
    let currentValue: String
    let previousValue: String
    let label: String
    let improvement: Bool?  // nil = no change, true = improvement, false = decline

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .lastTextBaseline) {
                Text(currentValue)
                    .font(Theme.Fonts.display(24))
                    .foregroundColor(Theme.Colors.textPrimary)

                if let improvement {
                    Image(systemName: improvement ? "arrow.up.right" : "arrow.down.right")
                        .foregroundColor(improvement ? Theme.Colors.optimal : Theme.Colors.caution)
                        .font(.system(size: 12))
                }

                Text("from \(previousValue)")
                    .font(Theme.Fonts.label(11))
                    .foregroundColor(Theme.Colors.textTertiary)
            }

            Text(label.uppercased())
                .font(Theme.Fonts.label(11))
                .tracking(0.5)
                .foregroundColor(Theme.Colors.textSecondary)
        }
    }
}

// MARK: - Metric Trend Badge

/// Badge showing trend direction for metric tiles
struct MetricTrendBadge: View {
    let trend: TrendDirection
    let value: String?

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trendIcon)
                .font(.system(size: 10, weight: .bold))

            if let value {
                Text(value)
                    .font(Theme.Fonts.label(10))
            }
        }
        .foregroundColor(trendColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(trendColor.opacity(0.15))
        .clipShape(Capsule())
    }

    private var trendIcon: String {
        switch trend {
        case .improving: return "arrow.up"
        case .declining: return "arrow.down"
        case .stable: return "minus"
        }
    }

    private var trendColor: Color {
        switch trend {
        case .improving: return Theme.Colors.optimal
        case .declining: return Theme.Colors.caution
        case .stable: return Theme.Colors.neutral
        }
    }
}

// MARK: - Preview

#Preview("Metric Tiles") {
    LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible())
    ], spacing: Theme.Spacing.cardGap) {
        MetricTile(
            icon: "waveform.path.ecg",
            value: "45ms",
            label: "HRV",
            sublabel: "+12%",
            color: Theme.Colors.optimal
        )

        MetricTile(
            icon: "heart.fill",
            value: "58 bpm",
            label: "RHR",
            sublabel: "Normal",
            color: Theme.Colors.neutral
        )

        MetricTile(
            icon: "flame.fill",
            value: "12.5",
            label: "Strain",
            color: Theme.Colors.caution
        )

        MetricTile(
            icon: "bed.double.fill",
            value: "7h 23m",
            label: "Sleep",
            sublabel: "85%",
            color: Theme.Colors.sleepPerformance(score: 85)
        )
    }
    .padding()
    .background(Theme.Colors.primary)
}
