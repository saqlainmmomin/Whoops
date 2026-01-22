import SwiftUI

/// Session 7: Whoop-aligned Sleep Tab
/// Week-view first approach with bedtime-to-wake visualization
struct SleepTab: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var selectedDay: Date?
    @State private var selectedWeek: Date = WeekAggregator.currentWeekStart()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.moduleP) {

                // Week selector
                WeekSelector(
                    currentWeek: selectedWeek,
                    onPreviousWeek: { goToPreviousWeek() },
                    onNextWeek: { goToNextWeek() }
                )

                // 3-metric summary
                HStack(spacing: Theme.Spacing.cardGap) {
                    SleepMetricBox(
                        value: "\(weekSleepPerformance)%",
                        label: "Performance"
                    )
                    SleepMetricBox(
                        value: hoursVsNeedFormatted,
                        label: "Hrs vs Need"
                    )
                    SleepMetricBox(
                        value: timeInBedFormatted,
                        label: "Time in Bed"
                    )
                }
                .padding(.horizontal, Theme.Spacing.moduleP)

                // Consistency row
                HStack {
                    Text("CONSISTENCY")
                        .font(Theme.Fonts.label(11))
                        .foregroundColor(Theme.Colors.textSecondary)
                    Spacer()
                    Text("\(Int(sleepConsistency * 100))%")
                        .font(Theme.Fonts.display(17))
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                .padding(.horizontal, Theme.Spacing.moduleP)

                // Week bar chart (bedtime-to-wake windows)
                WeekBarChart(
                    sleepData: weekSleepBars,
                    selectedDay: selectedDay,
                    onDayTap: { day in
                        withAnimation {
                            selectedDay = selectedDay == day ? nil : day
                        }
                    }
                )
                .frame(height: 200)
                .padding(.horizontal, Theme.Spacing.moduleP)

                // If day selected, show stages breakdown
                if let day = selectedDay,
                   let sleepDetail = sleepDetail(for: day) {
                    SleepStagesCard(sleep: sleepDetail)
                        .padding(.horizontal, Theme.Spacing.moduleP)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Insight card
                if let insight = sleepInsight {
                    InsightCard(
                        icon: "moon.zzz.fill",
                        heading: "Sleep Schedule",
                        body: insight,
                        accentColor: Theme.Colors.neutral
                    )
                    .padding(.horizontal, Theme.Spacing.moduleP)
                }
            }
            .padding(.vertical, Theme.Spacing.moduleP)
        }
        .background(Theme.Colors.primary)
    }

    // MARK: - Week Navigation

    private func goToPreviousWeek() {
        withAnimation {
            selectedWeek = WeekAggregator.previousWeekStart(from: selectedWeek)
            selectedDay = nil
        }
    }

    private func goToNextWeek() {
        let nextWeek = WeekAggregator.nextWeekStart(from: selectedWeek)
        if !WeekAggregator.isWeekInFuture(nextWeek) {
            withAnimation {
                selectedWeek = nextWeek
                selectedDay = nil
            }
        }
    }

    // MARK: - Computed Properties

    private var weekMetrics: [DailyMetrics] {
        let calendar = Calendar.current
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: selectedWeek) else { return nil }
            return viewModel.weeklyMetrics.first { calendar.isDate($0.date, inSameDayAs: date) }
        }
    }

    private var weekSleepPerformance: Int {
        let performances = weekMetrics.compactMap { metric -> Int? in
            if let analysis = metric.sleepAnalysis {
                return Int(analysis.performanceScore)
            } else if let sleep = metric.sleep {
                return Int(sleep.averageEfficiency)
            }
            return nil
        }
        guard !performances.isEmpty else { return 0 }
        return performances.reduce(0, +) / performances.count
    }

    private var hoursVsNeedFormatted: String {
        let totalHours = weekMetrics.compactMap { $0.sleep?.totalSleepHours }.reduce(0, +)
        let avgHours = weekMetrics.isEmpty ? 0 : totalHours / Double(weekMetrics.count)
        let needed = 7.5 // Default
        return String(format: "%.1f:%.1f", avgHours, needed)
    }

    private var timeInBedFormatted: String {
        let totalDuration = weekMetrics.compactMap { metric -> Double? in
            if let session = metric.sleep?.primarySession {
                return session.totalDurationHours
            }
            return nil
        }.reduce(0, +)

        let avgHours = weekMetrics.isEmpty ? 0 : totalDuration / Double(weekMetrics.count)
        let hours = Int(avgHours)
        let minutes = Int((avgHours - Double(hours)) * 60)
        return "\(hours)h \(minutes)m"
    }

    private var sleepConsistency: Double {
        let summaries = weekMetrics.compactMap { $0.sleep }
        let consistency = ConsistencyCalculator.calculate(from: summaries)
        return consistency.consistencyScore
    }

    private var weekSleepBars: [DailySleepBar] {
        let calendar = Calendar.current
        return (0..<7).compactMap { offset -> DailySleepBar? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: selectedWeek) else { return nil }

            if let metric = weekMetrics.first(where: { calendar.isDate($0.date, inSameDayAs: date) }),
               let sleep = metric.sleep,
               let bedtime = sleep.bedtime,
               let wakeTime = sleep.wakeTime {
                let efficiency = Int(sleep.averageEfficiency)
                return DailySleepBar(
                    date: date,
                    bedtime: bedtime,
                    wakeTime: wakeTime,
                    performanceColor: Theme.Colors.sleepPerformance(score: efficiency)
                )
            }
            // Return placeholder for missing data
            return DailySleepBar(
                date: date,
                bedtime: calendar.date(bySettingHour: 23, minute: 0, second: 0, of: date) ?? date,
                wakeTime: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: date) ?? date,
                performanceColor: Theme.Colors.tertiary
            )
        }
    }

    private func sleepDetail(for date: Date) -> SleepAnalysis? {
        let calendar = Calendar.current
        guard let metric = weekMetrics.first(where: { calendar.isDate($0.date, inSameDayAs: date) }),
              let sleep = metric.sleep,
              let bedtime = sleep.bedtime,
              let wakeTime = sleep.wakeTime else {
            return nil
        }

        let breakdown = sleep.combinedStageBreakdown
        return SleepAnalysis(
            totalDuration: sleep.totalSleepDuration,
            hoursNeeded: 7.5, // Default
            hoursVsNeed: sleep.totalSleepHours / 7.5,
            efficiency: sleep.averageEfficiency / 100,
            consistency: sleepConsistency,
            performanceScore: sleep.averageEfficiency,
            bedtime: bedtime,
            wakeTime: wakeTime,
            stages: SleepStages(
                deepMinutes: breakdown.deepMinutes,
                remMinutes: breakdown.remMinutes,
                coreMinutes: breakdown.coreMinutes,
                awakeMinutes: breakdown.awakeMinutes
            )
        )
    }

    private var sleepInsight: String? {
        if sleepConsistency < 0.6 {
            return "Your bedtime varies significantly. Try setting a consistent bedtime to improve recovery."
        } else if weekSleepPerformance < 70 {
            return "You're averaging below optimal sleep. Consider going to bed 30 minutes earlier."
        } else if weekSleepPerformance >= 85 {
            return "Great sleep consistency this week! Keep maintaining your schedule."
        }
        return nil
    }
}

#Preview {
    SleepTab(viewModel: DashboardViewModel(healthKitManager: HealthKitManager()))
        .preferredColorScheme(.dark)
}
