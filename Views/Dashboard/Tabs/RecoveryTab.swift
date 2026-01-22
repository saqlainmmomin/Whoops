import SwiftUI

/// Session 7: Whoop-aligned Recovery Tab
/// Focus on recovery score breakdown with horizontal progress bars
struct RecoveryTab: View {
    @ObservedObject var viewModel: DashboardViewModel

    private var recoveryScore: Int {
        viewModel.todayMetrics?.recoveryScore?.score ?? 0
    }

    private var hrvValue: Double {
        viewModel.todayMetrics?.hrv?.nightlySDNN ?? viewModel.todayMetrics?.hrv?.averageSDNN ?? 0
    }

    private var rhrValue: Double {
        viewModel.todayMetrics?.heartRate?.restingBPM ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.moduleP) {

                // Hero gauge (same as Overview)
                CircularProgressGauge(
                    value: Double(recoveryScore),
                    color: Theme.Colors.recovery(score: recoveryScore),
                    label: "Recovery",
                    sublabel: nil
                )
                .frame(width: 180, height: 180)

                // 4 horizontal progress bars (breakdown)
                VStack(spacing: 16) {
                    RecoveryComponentBar(
                        label: "HRV Deviation",
                        value: viewModel.hrvDeviationPercent ?? 0,
                        suffix: "%",
                        progress: hrvComponentProgress,
                        color: Theme.Colors.hrv(deviationPercent: viewModel.hrvDeviationPercent ?? 0)
                    )

                    RecoveryComponentBar(
                        label: "Resting HR Deviation",
                        value: viewModel.rhrDeviationPercent ?? 0,
                        suffix: "%",
                        progress: rhrComponentProgress,
                        color: (viewModel.rhrDeviationPercent ?? 0) < 0 ? Theme.Colors.optimal : Theme.Colors.caution
                    )

                    RecoveryComponentBar(
                        label: "Sleep Quality",
                        value: Double(sleepPerformance),
                        suffix: "%",
                        progress: Double(sleepPerformance) / 100,
                        color: Theme.Colors.sleepPerformance(score: sleepPerformance)
                    )

                    RecoveryComponentBar(
                        label: "Previous Day Strain",
                        value: previousDayStrain,
                        suffix: "",
                        progress: previousDayStrain / 21,
                        color: Theme.Colors.neutral
                    )
                }
                .padding(.horizontal, Theme.Spacing.moduleP)

                // 7-day trend sparkline (REPLACES "VS. PREVIOUS 30 DAYS")
                VStack(alignment: .leading, spacing: 8) {
                    Text("7-DAY TREND")
                        .font(Theme.Fonts.label(11))
                        .foregroundColor(Theme.Colors.textSecondary)

                    if !viewModel.recoverySparklineData.isEmpty {
                        SparklineChart(
                            data: viewModel.recoverySparklineData,
                            color: Theme.Colors.optimal
                        )
                        .frame(height: 60)
                    }
                }
                .padding(.horizontal, Theme.Spacing.moduleP)

                // Explanation text
                Text("Recovery indicates autonomic nervous system balance. Higher HRV and lower RHR signal readiness.")
                    .font(Theme.Fonts.body)
                    .foregroundColor(Theme.Colors.textTertiary)
                    .padding(.horizontal, Theme.Spacing.moduleP)
            }
            .padding(.vertical, Theme.Spacing.moduleP)
        }
        .background(Theme.Colors.primary)
    }

    // MARK: - Computed Properties

    private var hrvComponentProgress: Double {
        guard let deviation = viewModel.hrvDeviationPercent else { return 0.5 }
        // Normalize -30% to +30% to 0-1
        return (deviation + 30) / 60
    }

    private var rhrComponentProgress: Double {
        guard let deviation = viewModel.rhrDeviationPercent else { return 0.5 }
        // Normalize -20% to +20% to 0-1 (inverted: lower is better)
        return (-deviation + 20) / 40
    }

    private var sleepPerformance: Int {
        guard let sleep = viewModel.todayMetrics?.sleep else { return 0 }
        return Int(sleep.averageEfficiency)
    }

    private var previousDayStrain: Double {
        // Get yesterday's strain from weekly metrics
        guard viewModel.weeklyMetrics.count >= 2 else { return 0 }
        let yesterdayIndex = viewModel.weeklyMetrics.count - 2
        if let strain = viewModel.weeklyMetrics[yesterdayIndex].strainScore?.score {
            return Double(strain) / 100.0 * 21.0
        }
        return 0
    }
}

// MARK: - Legacy Components (kept for backward compatibility)

struct RecoveryComponentsCard: View {
    let recovery: RecoveryScore

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("SCORE BREAKDOWN")
                .font(Theme.Fonts.label(11))
                .foregroundStyle(Theme.Colors.textTertiary)
                .tracking(1)

            ForEach(recovery.components) { component in
                ComponentRow(component: component)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Theme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

struct ComponentRow: View {
    let component: ScoreComponent

    var body: some View {
        HStack {
            Text(component.name.uppercased())
                .font(Theme.Fonts.label(10))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(1)

            Spacer()

            Text(component.formattedContribution)
                .font(Theme.Fonts.mono(12))
                .foregroundStyle(Theme.Colors.textPrimary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.Colors.borderSubtle)
                        .frame(width: geo.size.width)

                    Rectangle()
                        .fill(Theme.Colors.recoveryColor(for: component.normalizedValue))
                        .frame(width: geo.size.width * (component.normalizedValue / 100))
                }
            }
            .frame(width: 60, height: 4)
            .clipShape(Capsule())
        }
    }
}

struct BiometricDetailCard: View {
    let title: String
    let value: String
    let unit: String
    let deviation: Double?
    let trend: TrendDirection?
    let sparklineData: [Double]
    let positiveIsGood: Bool

    private var deviationColor: Color {
        guard let dev = deviation else { return Theme.Colors.textTertiary }
        if positiveIsGood {
            return dev >= 0 ? Theme.Colors.optimal : Theme.Colors.critical
        } else {
            return dev <= 0 ? Theme.Colors.optimal : Theme.Colors.caution
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(title)
                    .font(Theme.Fonts.label(11))
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .tracking(1)

                Spacer()

                if let t = trend {
                    Image(systemName: trendIcon(for: t))
                        .font(.system(size: 10))
                        .foregroundStyle(trendColor(for: t))
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(Theme.Fonts.display(24))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(unit)
                    .font(Theme.Fonts.label(10))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            if let dev = deviation {
                Text("\(dev >= 0 ? "+" : "")\(Int(dev))% from baseline")
                    .font(Theme.Fonts.label(10))
                    .foregroundStyle(deviationColor)
            }

            if !sparklineData.isEmpty {
                SparklineChart(data: sparklineData, color: deviationColor)
                    .frame(height: 30)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func trendIcon(for trend: TrendDirection) -> String {
        switch trend {
        case .improving, .increasing: return "arrow.up.right"
        case .declining, .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    private func trendColor(for trend: TrendDirection) -> Color {
        switch trend {
        case .improving, .increasing: return Theme.Colors.optimal
        case .declining, .decreasing: return Theme.Colors.caution
        case .stable: return Theme.Colors.neutral
        }
    }
}

#Preview {
    RecoveryTab(viewModel: DashboardViewModel(healthKitManager: HealthKitManager()))
        .preferredColorScheme(.dark)
}
