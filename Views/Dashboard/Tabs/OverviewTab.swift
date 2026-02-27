import SwiftUI

/// Pixel-Perfect Whoop Overview Tab
/// Features dual gauge hero, baseline info, activities, and key statistics
struct OverviewTab: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showBaselineVideo = false

    // Computed properties for display
    private var recoveryScore: Int {
        viewModel.todayMetrics?.recoveryScore?.score ?? 0
    }

    private var strainScore: Double {
        viewModel.strainScoreNormalized
    }

    private var hrvFormatted: String {
        guard let hrv = viewModel.todayMetrics?.hrv else { return "--" }
        let value = Int(hrv.nightlySDNN ?? hrv.averageSDNN)
        return "\(value)ms"
    }

    private var sleepPerformanceFormatted: String {
        guard let sleep = viewModel.todayMetrics?.sleep else { return "--" }
        return "\(Int(sleep.averageEfficiency))%"
    }

    private var baselineDaysCompleted: Int {
        // Calculate days with data in last 28 days
        min(viewModel.weeklyMetrics.count, 28)
    }

    private var shouldShowBaselineCard: Bool {
        baselineDaysCompleted < 28
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.moduleP) {

                // HERO: Dual Gauge (Recovery + Strain)
                DualGaugeHero(
                    recoveryScore: recoveryScore,
                    strainScore: strainScore,
                    hrvValue: hrvFormatted,
                    sleepPerformance: sleepPerformanceFormatted
                )
                .padding(.top, Theme.Spacing.moduleP)

                // Baseline Info Card (if < 28 days)
                if shouldShowBaselineCard {
                    BaselineInfoCard(
                        daysCompleted: baselineDaysCompleted,
                        totalDays: 28,
                        onWatchVideo: { showBaselineVideo = true }
                    )
                    .padding(.horizontal, Theme.Spacing.moduleP)
                }

                // Alarm & Bedtime Row (now connected to AlarmManager)
                AlarmBedtimeRow()
                    .padding(.horizontal, Theme.Spacing.moduleP)

                // Activities Section
                activitiesSection
                    .padding(.horizontal, Theme.Spacing.moduleP)

                // Key Statistics Section
                keyStatisticsSection
                    .padding(.horizontal, Theme.Spacing.moduleP)
            }
            .padding(.bottom, Theme.Spacing.moduleP)
        }
        .background(Theme.Colors.primary)
    }

    // MARK: - Activities Section

    @ViewBuilder
    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with "START ACTIVITY" button
            HStack {
                Text("TODAY'S ACTIVITIES")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .tracking(0.5)

                Spacer()

                Button(action: { /* TODO: Start activity */ }) {
                    HStack(spacing: 4) {
                        Text("START ACTIVITY")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.Colors.whoopTeal)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Theme.Colors.whoopTeal)
                    }
                }
            }

            // Sleep activity (always show if we have sleep data)
            if let sleep = viewModel.todayMetrics?.sleep,
               let bedtime = sleep.bedtime,
               let wakeTime = sleep.wakeTime {
                SleepActivityRow(
                    bedtime: formatTime(bedtime),
                    wakeTime: formatTime(wakeTime),
                    duration: formatDuration(sleep.totalSleepHours),
                    quality: nil
                )
            }

            // Workout activities
            if let workouts = viewModel.todayWorkouts {
                ForEach(workouts) { workout in
                    ActivityRow(
                        icon: iconForWorkout(workout.type),
                        activityType: workout.type.capitalized,
                        timeRange: formatTimeRange(workout.startTime, duration: workout.duration),
                        detail: formatDuration(workout.duration / 3600),
                        iconColor: Theme.Colors.whoopCyan
                    )
                }
            }
        }
    }

    // MARK: - Key Statistics Section

    private var keyStatisticsSection: some View {
        KeyStatisticsSection(
            stats: [
                KeyStat(
                    icon: "waveform.path.ecg",
                    label: "HRV",
                    value: String(Int(viewModel.todayMetrics?.hrv?.nightlySDNN ?? viewModel.todayMetrics?.hrv?.averageSDNN ?? 0)),
                    unit: "ms",
                    trend: viewModel.hrvTrend,
                    baseline: viewModel.sevenDayBaseline?.averageHRV.map { "\(Int($0))ms" }
                ),
                KeyStat(
                    icon: "moon.fill",
                    label: "Sleep Performance",
                    value: String(Int(viewModel.todayMetrics?.sleep?.averageEfficiency ?? 0)),
                    unit: "%",
                    trend: viewModel.sleepTrend,
                    baseline: nil
                ),
                KeyStat(
                    icon: "flame.fill",
                    label: "Calories",
                    value: formatCalories(viewModel.todayMetrics?.activity?.activeEnergy ?? 0),
                    trend: nil,
                    baseline: viewModel.sevenDayBaseline?.averageActiveEnergy.map { formatCalories($0) }
                ),
                KeyStat(
                    icon: "bed.double.fill",
                    label: "Hours of Sleep",
                    value: formatDuration(viewModel.todayMetrics?.sleep?.totalSleepHours ?? 0),
                    trend: viewModel.sleepTrend,
                    baseline: viewModel.sevenDayBaseline?.averageSleepDuration.map { formatDuration($0) }
                )
            ],
            onCustomize: { /* TODO: Show customization sheet */ }
        )
    }

    // MARK: - Formatting Helpers

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func formatTimeRange(_ start: Date, duration: TimeInterval) -> String {
        let end = start.addingTimeInterval(duration)
        return "\(formatTime(start)) - \(formatTime(end))"
    }

    private func formatDuration(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h > 0 {
            return "\(h)h \(m)m"
        } else {
            return "\(m)m"
        }
    }

    private func formatCalories(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        } else {
            return "\(Int(value))"
        }
    }

    private func iconForWorkout(_ type: String) -> String {
        switch type.lowercased() {
        case "running": return "figure.run"
        case "cycling": return "figure.outdoor.cycle"
        case "swimming": return "figure.pool.swim"
        case "walking": return "figure.walk"
        case "strength", "functional strength training": return "dumbbell.fill"
        case "yoga": return "figure.mind.and.body"
        case "hiit", "high intensity interval training": return "bolt.fill"
        default: return "figure.mixed.cardio"
        }
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
