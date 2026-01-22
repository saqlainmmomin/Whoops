import SwiftUI

/// Session 7: Whoop-aligned Overview Tab
/// Clean design with single recovery gauge and metric tiles
struct OverviewTab: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.moduleP) {

                // HERO: Recovery gauge (SINGLE, not dual)
                CircularProgressGauge(
                    value: Double(viewModel.todayMetrics?.recoveryScore?.score ?? 0),
                    color: Theme.Colors.recovery(score: viewModel.todayMetrics?.recoveryScore?.score ?? 0),
                    label: "Recovery",
                    sublabel: viewModel.recoveryCategory
                )
                .frame(width: 200, height: 200)
                .padding(.top, Theme.Spacing.moduleP)

                // 4-metric tiles (2-column grid)
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Theme.Spacing.cardGap) {

                    MetricTile(
                        icon: "waveform.path.ecg",
                        value: formatHRV(viewModel.todayMetrics?.hrv),
                        label: "HRV",
                        sublabel: formatHRVDeviation(viewModel.hrvDeviationPercent),
                        color: Theme.Colors.hrv(deviationPercent: viewModel.hrvDeviationPercent ?? 0)
                    )

                    MetricTile(
                        icon: "heart.fill",
                        value: formatRHR(viewModel.todayMetrics?.heartRate?.restingBPM),
                        label: "RHR",
                        sublabel: formatRHRTrend(viewModel.rhrTrend),
                        color: Theme.Colors.neutral
                    )

                    MetricTile(
                        icon: "flame.fill",
                        value: String(format: "%.1f", viewModel.strainScoreNormalized),
                        label: "Strain",
                        sublabel: nil,
                        color: Theme.Colors.strain(
                            current: viewModel.strainScoreNormalized,
                            target: viewModel.optimalStrainTarget ?? 14.0
                        )
                    )

                    MetricTile(
                        icon: "bed.double.fill",
                        value: formatSleepDuration(viewModel.todayMetrics?.sleep),
                        label: "Sleep",
                        sublabel: formatSleepPerformance(viewModel.todayMetrics),
                        color: sleepColor(viewModel.todayMetrics)
                    )
                }
                .padding(.horizontal, Theme.Spacing.moduleP)

                // Contextual insight
                if let insight = viewModel.newPrimaryInsight {
                    InsightCard(
                        icon: insight.icon,
                        heading: insight.title,
                        body: insight.message,
                        accentColor: insight.color
                    )
                    .padding(.horizontal, Theme.Spacing.moduleP)
                }

                // Activity feed: actual workouts only (NO "Start Activity" CTA)
                if let workouts = viewModel.todayWorkouts, !workouts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ACTIVITY")
                            .font(Theme.Fonts.label(11))
                            .tracking(1)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .padding(.horizontal, Theme.Spacing.moduleP)

                        ForEach(workouts) { workout in
                            WorkoutRow(workout: workout)
                        }
                        .padding(.horizontal, Theme.Spacing.moduleP)
                    }
                }
            }
            .padding(.bottom, Theme.Spacing.moduleP)
        }
        .background(Theme.Colors.primary)
    }

    // MARK: - Formatting Helpers

    private func formatHRV(_ hrv: DailyHRVSummary?) -> String {
        guard let hrv = hrv else { return "--" }
        let value = Int(hrv.nightlySDNN ?? hrv.averageSDNN)
        return "\(value)ms"
    }

    private func formatHRVDeviation(_ deviation: Double?) -> String? {
        guard let deviation = deviation else { return nil }
        let sign = deviation >= 0 ? "+" : ""
        return "\(sign)\(Int(deviation))%"
    }

    private func formatRHR(_ rhr: Double?) -> String {
        guard let rhr = rhr else { return "--" }
        return "\(Int(rhr)) bpm"
    }

    private func formatRHRTrend(_ trend: TrendDirection?) -> String? {
        guard let trend = trend else { return nil }
        switch trend {
        case .improving: return "Lower"
        case .declining: return "Higher"
        case .stable: return "Stable"
        default: return nil
        }
    }

    private func formatSleepDuration(_ sleep: DailySleepSummary?) -> String {
        guard let sleep = sleep else { return "--" }
        let hours = Int(sleep.totalSleepHours)
        let minutes = Int((sleep.totalSleepHours - Double(hours)) * 60)
        return "\(hours)h \(minutes)m"
    }

    private func formatSleepPerformance(_ metrics: DailyMetrics?) -> String? {
        guard let metrics = metrics,
              let sleep = metrics.sleep else { return nil }
        let efficiency = Int(sleep.averageEfficiency)
        return "\(efficiency)%"
    }

    private func sleepColor(_ metrics: DailyMetrics?) -> Color {
        guard let metrics = metrics,
              let sleep = metrics.sleep else { return Theme.Colors.neutral }
        let efficiency = Int(sleep.averageEfficiency)
        return Theme.Colors.sleepPerformance(score: efficiency)
    }
}

// MARK: - ViewModel Extension for New Properties

extension DashboardViewModel {
    /// Primary insight using new InsightCard format
    var newPrimaryInsight: PrimaryInsight? {
        guard let metrics = todayMetrics,
              let recovery = metrics.recoveryScore else { return nil }

        return PrimaryInsight.recovery(
            score: recovery.score,
            hrvDeviation: hrvDeviationPercent ?? 0
        )
    }

    /// Today's workouts as WorkoutEntry array
    var todayWorkouts: [WorkoutEntry]? {
        guard let workoutSummary = todayMetrics?.workouts,
              workoutSummary.totalWorkouts > 0 else { return nil }

        // Convert from DailyWorkoutSummary to WorkoutEntry array
        return workoutSummary.workouts.map { session in
            WorkoutEntry(
                type: session.activityType.rawValue,
                startTime: session.startDate,
                duration: session.duration,
                strain: 0, // Strain calculated separately
                averageHeartRate: session.averageHeartRate,
                maxHeartRate: session.maxHeartRate,
                activeCalories: session.totalEnergyBurned ?? 0
            )
        }
    }
}

#Preview {
    OverviewTab(viewModel: DashboardViewModel(healthKitManager: HealthKitManager()))
        .preferredColorScheme(.dark)
}
