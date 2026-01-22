import SwiftUI

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
            VStack(spacing: Theme.Spacing.lg) {
                // Main recovery ring
                RecoveryRing(
                    score: Double(recoveryScore),
                    category: viewModel.recoveryCategory,
                    weeklyAverage: viewModel.weeklyRecoveryAvg
                )
                .padding(.top, Theme.Spacing.lg)

                // Recovery components breakdown
                if let recovery = viewModel.todayMetrics?.recoveryScore {
                    RecoveryComponentsCard(recovery: recovery)
                        .padding(.horizontal)
                }

                // Biometrics row
                HStack(spacing: Theme.Spacing.xl) {
                    BiometricDetailCard(
                        title: "HRV",
                        value: String(format: "%.0f", hrvValue),
                        unit: "ms",
                        deviation: viewModel.hrvDeviationPercent,
                        trend: viewModel.hrvTrend,
                        sparklineData: viewModel.hrvSparklineData,
                        positiveIsGood: true
                    )

                    BiometricDetailCard(
                        title: "RHR",
                        value: String(format: "%.0f", rhrValue),
                        unit: "bpm",
                        deviation: viewModel.rhrDeviationPercent,
                        trend: viewModel.rhrTrend,
                        sparklineData: viewModel.rhrSparklineData,
                        positiveIsGood: false
                    )
                }
                .padding(.horizontal)

                // Weekly trend
                if !viewModel.recoverySparklineData.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("7-DAY RECOVERY TREND")
                            .font(Theme.Fonts.label(11))
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .tracking(1)

                        SparklineChart(
                            data: viewModel.recoverySparklineData,
                            color: Theme.Colors.recoveryColor(for: Double(recoveryScore))
                        )
                        .frame(height: 60)
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: Theme.Spacing.xl)
            }
            .padding(.vertical, Theme.Spacing.lg)
        }
        .background(Theme.Colors.void)
    }
}

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

            // Progress indicator
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
            return dev >= 0 ? Theme.Colors.hrvPositive : Theme.Colors.hrvNegative
        } else {
            return dev <= 0 ? Theme.Colors.rhrPositive : Theme.Colors.rhrNegative
        }
    }

    private var trendIcon: String {
        switch trend {
        case .improving: return "arrow.up.right"
        case .declining: return "arrow.down.right"
        case .stable: return "arrow.right"
        case .none: return "minus"
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
                    Image(systemName: trendIcon)
                        .font(.system(size: 10))
                        .foregroundStyle(trendColor(for: t))
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(Theme.Fonts.mono(24))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(unit)
                    .font(Theme.Fonts.label(10))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            if let dev = deviation {
                Text("\(dev >= 0 ? "+" : "")\(Int(dev))% from baseline")
                    .font(Theme.Fonts.mono(10))
                    .foregroundStyle(deviationColor)
            }

            if !sparklineData.isEmpty {
                SparklineChart(data: sparklineData, color: deviationColor)
                    .frame(height: 30)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Theme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private func trendColor(for trend: TrendDirection) -> Color {
        switch trend {
        case .improving: return Theme.Colors.hrvPositive
        case .declining: return Theme.Colors.hrvNegative
        case .stable: return Theme.Colors.textTertiary
        }
    }
}

#Preview {
    RecoveryTab(viewModel: DashboardViewModel(healthKitManager: HealthKitManager()))
        .preferredColorScheme(.dark)
}
