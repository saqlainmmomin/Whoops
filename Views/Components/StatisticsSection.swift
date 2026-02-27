import SwiftUI

/// Whoop-style statistics section with header and stat rows
/// Matches WHOOP design: value on right with baseline below, trend arrow next to value
struct StatisticsSection: View {
    let title: String
    let stats: [StatRow]
    var rightLabel: String? = nil
    var showAddButton: Bool = false
    var onAddTap: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .tracking(0.5)

                Spacer()

                if let rightLabel = rightLabel {
                    Text(rightLabel)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Theme.Colors.textTertiary)
                        .tracking(0.5)
                }

                if showAddButton {
                    Button(action: { onAddTap?() }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 28, height: 28)
                            .background(Theme.Colors.textPrimary)
                            .clipShape(Circle())
                    }
                }
            }

            // Stat rows
            VStack(spacing: 0) {
                ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                    WhoopStatRowView(stat: stat)

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

/// Model for a single statistic row
struct StatRow: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let value: String
    let trend: TrendDirection?
    let baseline: String?

    init(icon: String, label: String, value: String, trend: TrendDirection? = nil, baseline: String? = nil) {
        self.icon = icon
        self.label = label
        self.value = value
        self.trend = trend
        self.baseline = baseline
    }
}

/// WHOOP-style stat row: Icon | Label | Value with trend + baseline below
struct WhoopStatRowView: View {
    let stat: StatRow

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

            Spacer()

            // Value + Trend + Baseline stack
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 6) {
                    Text(stat.value)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)

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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

/// WHOOP-style trend arrow
struct WhoopTrendArrow: View {
    let direction: TrendDirection

    var body: some View {
        Image(systemName: arrowIcon)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(arrowColor)
    }

    private var arrowIcon: String {
        switch direction {
        case .improving: return "arrowtriangle.up.fill"
        case .declining: return "arrowtriangle.down.fill"
        case .stable: return "minus"
        }
    }

    private var arrowColor: Color {
        switch direction {
        case .improving: return Color(hex: "#00D4AA") // Teal/green
        case .declining: return Color(hex: "#FF6B6B") // Red
        case .stable: return Theme.Colors.textTertiary
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        StatisticsSection(
            title: "RECOVERY STATISTICS",
            stats: [
                StatRow(icon: "waveform.path.ecg", label: "HRV", value: "39", trend: .improving, baseline: "36"),
                StatRow(icon: "heart.fill", label: "RHR", value: "56", trend: .declining, baseline: "58"),
                StatRow(icon: "lungs.fill", label: "Respiratory Rate", value: "12.7", trend: .improving, baseline: "12.6"),
                StatRow(icon: "moon.fill", label: "Sleep Performance", value: "66%", trend: .declining, baseline: "75%")
            ],
            rightLabel: "VS. PREVIOUS 30 DAYS"
        )

        StatisticsSection(
            title: "STRAIN STATISTICS",
            stats: [
                StatRow(icon: "heart.fill", label: "Average HR", value: "67", trend: .stable, baseline: "68"),
                StatRow(icon: "flame.fill", label: "Calories", value: "2,260", trend: .improving, baseline: "1,947")
            ],
            rightLabel: "VS. PREVIOUS 30 DAYS"
        )
    }
    .padding()
    .background(Theme.Colors.primary)
}
