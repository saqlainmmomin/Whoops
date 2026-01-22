import SwiftUI

struct SleepTab: View {
    @ObservedObject var viewModel: DashboardViewModel

    private var sleepHours: Double {
        viewModel.todayMetrics?.sleep?.totalSleepHours ?? 0
    }

    private var sleepEfficiency: Double {
        viewModel.todayMetrics?.sleep?.averageEfficiency ?? 0
    }

    private var sleepDebtHours: Double {
        viewModel.todayMetrics?.sleepDebt?.debtHours ?? 0
    }

    private var sleepColor: Color {
        if sleepHours >= 7.5 {
            return Theme.Colors.sleepOptimal
        } else if sleepHours >= 6.5 {
            return Theme.Colors.sleepSufficient
        } else {
            return Theme.Colors.sleepPoor
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Sleep duration ring
                ZStack {
                    Circle()
                        .stroke(Theme.Colors.borderSubtle, lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: min(sleepHours / 10.0, 1.0))
                        .stroke(
                            LinearGradient(
                                colors: [sleepColor, sleepColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 4) {
                        Text(String(format: "%.1f", sleepHours))
                            .font(Theme.Fonts.display(56))
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text("HOURS")
                            .font(Theme.Fonts.label(10))
                            .foregroundStyle(sleepColor)
                            .tracking(2)
                    }
                }
                .frame(width: 180, height: 180)
                .glow(color: sleepColor, radius: 12, opacity: 0.3)
                .padding(.top, Theme.Spacing.lg)

                // Sleep stats grid
                HStack(spacing: Theme.Spacing.lg) {
                    SleepStatCard(
                        title: "EFFICIENCY",
                        value: String(format: "%.0f%%", sleepEfficiency * 100),
                        subtitle: "Time asleep"
                    )

                    SleepStatCard(
                        title: "DEBT",
                        value: String(format: "%.1fh", sleepDebtHours),
                        subtitle: "This week"
                    )
                }
                .padding(.horizontal)

                // Sleep stages breakdown
                if let sleep = viewModel.todayMetrics?.sleep {
                    SleepStagesCard(sleep: sleep)
                        .padding(.horizontal)
                }

                // Weekly sparkline
                if !viewModel.sleepSparklineData.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("7-DAY TREND")
                            .font(Theme.Fonts.label(11))
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .tracking(1)

                        SparklineChart(data: viewModel.sleepSparklineData, color: sleepColor)
                            .frame(height: 60)
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: Theme.Spacing.xl)
            }
            .padding(.vertical, Theme.Spacing.lg)
        }
        .background(Theme.Gradients.sleepAmbient)
        .background(Theme.Colors.void)
    }
}

struct SleepStatCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(Theme.Fonts.label(10))
                .foregroundStyle(Theme.Colors.textTertiary)
                .tracking(1)

            Text(value)
                .font(Theme.Fonts.mono(28))
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(subtitle)
                .font(Theme.Fonts.label(10))
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Theme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

struct SleepStagesCard: View {
    let sleep: DailySleepSummary

    private var breakdown: SleepStageBreakdown { sleep.combinedStageBreakdown }
    private var remMinutes: Int { breakdown.remMinutes }
    private var deepMinutes: Int { breakdown.deepMinutes }
    private var coreMinutes: Int { breakdown.coreMinutes }
    private var awakeMinutes: Int { breakdown.awakeMinutes }
    private var totalMinutes: Int { max(breakdown.totalMinutes, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("SLEEP STAGES")
                .font(Theme.Fonts.label(11))
                .foregroundStyle(Theme.Colors.textTertiary)
                .tracking(1)

            // Stacked bar
            GeometryReader { geo in
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(Color(hex: "#4F46E5"))
                        .frame(width: geo.size.width * CGFloat(deepMinutes) / CGFloat(totalMinutes))

                    Rectangle()
                        .fill(Color(hex: "#7C3AED"))
                        .frame(width: geo.size.width * CGFloat(remMinutes) / CGFloat(totalMinutes))

                    Rectangle()
                        .fill(Color(hex: "#A78BFA"))
                        .frame(width: geo.size.width * CGFloat(coreMinutes) / CGFloat(totalMinutes))

                    Rectangle()
                        .fill(Theme.Colors.borderMedium)
                        .frame(width: geo.size.width * CGFloat(awakeMinutes) / CGFloat(totalMinutes))
                }
                .clipShape(Capsule())
            }
            .frame(height: 12)

            // Legend
            HStack(spacing: Theme.Spacing.md) {
                StageLegend(color: Color(hex: "#4F46E5"), label: "Deep", value: "\(deepMinutes)m")
                StageLegend(color: Color(hex: "#7C3AED"), label: "REM", value: "\(remMinutes)m")
                StageLegend(color: Color(hex: "#A78BFA"), label: "Core", value: "\(coreMinutes)m")
                StageLegend(color: Theme.Colors.borderMedium, label: "Awake", value: "\(awakeMinutes)m")
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

struct StageLegend: View {
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(Theme.Fonts.label(9))
                    .foregroundStyle(Theme.Colors.textTertiary)
                Text(value)
                    .font(Theme.Fonts.mono(10))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }
}

#Preview {
    SleepTab(viewModel: DashboardViewModel(healthKitManager: HealthKitManager()))
        .preferredColorScheme(.dark)
}
