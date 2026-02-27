import SwiftUI

/// Whoop-style key statistics section for Overview tab
/// Matches WHOOP design: Large value with trend arrow, baseline below
struct KeyStatisticsSection: View {
    let stats: [KeyStat]
    var onCustomize: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("KEY STATISTICS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .tracking(0.5)

                Spacer()

                if onCustomize != nil {
                    Button(action: { onCustomize?() }) {
                        HStack(spacing: 4) {
                            Text("CUSTOMIZE")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.Colors.textSecondary)
                            Image(systemName: "pencil")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
                }
            }

            // Stats list
            VStack(spacing: 0) {
                ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                    WhoopKeyStatRow(stat: stat, isLast: index == stats.count - 1)

                    if index < stats.count - 1 {
                        Divider()
                            .background(Theme.Colors.borderSubtle)
                            .padding(.leading, 44)
                    }
                }
            }
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cardCornerRadius))
        }
    }
}

/// Model for a key statistic
struct KeyStat: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let value: String
    let unit: String?
    let trend: TrendDirection?
    let baseline: String?

    init(
        icon: String,
        label: String,
        value: String,
        unit: String? = nil,
        trend: TrendDirection? = nil,
        baseline: String? = nil
    ) {
        self.icon = icon
        self.label = label
        self.value = value
        self.unit = unit
        self.trend = trend
        self.baseline = baseline
    }
}

/// WHOOP-style key stat row
struct WhoopKeyStatRow: View {
    let stat: KeyStat
    var isLast: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: stat.icon)
                .font(.system(size: 18))
                .foregroundColor(Theme.Colors.textSecondary)
                .frame(width: 24)

            // Label
            Text(stat.label.uppercased())
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.Colors.textPrimary)
                .tracking(0.3)
                .lineLimit(1)

            Spacer()

            // Value + Trend + Baseline
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 6) {
                    HStack(spacing: 0) {
                        Text(stat.value)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)

                        if let unit = stat.unit {
                            Text(unit)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Colors.textSecondary)
                                .offset(y: 2)
                        }
                    }

                    if let trend = stat.trend {
                        WhoopTrendArrow(direction: trend)
                    }
                }

                if let baseline = stat.baseline {
                    Text(baseline)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }

            // Add button for last row
            if isLast {
                Button(action: {}) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 24, height: 24)
                        .background(Theme.Colors.textPrimary)
                        .clipShape(Circle())
                }
                .padding(.leading, 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    KeyStatisticsSection(
        stats: [
            KeyStat(
                icon: "waveform.path.ecg",
                label: "HRV",
                value: "40",
                unit: nil,
                trend: .improving,
                baseline: "35"
            ),
            KeyStat(
                icon: "moon.fill",
                label: "Sleep Performance",
                value: "73",
                unit: "%",
                trend: .declining,
                baseline: "77%"
            ),
            KeyStat(
                icon: "flame.fill",
                label: "Calories",
                value: "1,702",
                trend: .stable,
                baseline: "1,860"
            ),
            KeyStat(
                icon: "bed.double.fill",
                label: "Hours of Sleep",
                value: "6:35",
                trend: nil,
                baseline: nil
            )
        ],
        onCustomize: {}
    )
    .padding()
    .background(Theme.Colors.primary)
}
