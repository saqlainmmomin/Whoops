import SwiftUI

struct OverviewTab: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Hero zone
                HStack(alignment: .center) {
                    BiometricSatellite(
                        type: .hrv,
                        value: viewModel.todayMetrics?.hrv?.nightlySDNN ?? viewModel.todayMetrics?.hrv?.averageSDNN ?? 0,
                        deviation: viewModel.hrvDeviationPercent
                    )

                    RecoveryRing(
                        score: Double(viewModel.todayMetrics?.recoveryScore?.score ?? 0),
                        category: viewModel.recoveryCategory,
                        weeklyAverage: viewModel.weeklyRecoveryAvg
                    )

                    BiometricSatellite(
                        type: .rhr,
                        value: viewModel.todayMetrics?.heartRate?.restingBPM ?? 0,
                        deviation: viewModel.rhrDeviationPercent
                    )
                }
                .padding(.horizontal)

                StrainArc(
                    score: viewModel.strainScoreNormalized,
                    targetStrain: viewModel.optimalStrainTarget,
                    weeklyAverage: viewModel.weeklyStrainAvg
                )

                if let insight = viewModel.primaryInsight {
                    InsightBanner(insight: insight)
                }

                Divider().background(Theme.Colors.borderSubtle).padding(.horizontal)

                HealthMonitorBadge(
                    metricsInRange: viewModel.metricsInRange,
                    totalMetrics: viewModel.totalMonitoredMetrics,
                    flaggedMetrics: viewModel.flaggedMetrics
                )
                .padding(.horizontal)

                Spacer(minLength: Theme.Spacing.xl)
            }
            .padding(.vertical, Theme.Spacing.lg)
        }
        .background(Theme.Colors.void)
    }
}

#Preview {
    OverviewTab(viewModel: DashboardViewModel(healthKitManager: HealthKitManager()))
        .preferredColorScheme(.dark)
}
