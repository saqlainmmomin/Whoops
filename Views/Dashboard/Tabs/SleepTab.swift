import SwiftUI

/// Pixel-Perfect Whoop Sleep Tab
/// Features dashed gauge, comparison boxes, statistics, and charts
struct SleepTab: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showSleepInfo = false

    // Computed properties
    private var sleepPerformance: Int {
        guard let sleep = viewModel.todayMetrics?.sleep else { return 0 }
        return Int(sleep.averageEfficiency)
    }

    private var hoursSleptFormatted: String {
        guard let sleep = viewModel.todayMetrics?.sleep else { return "--" }
        return formatDuration(sleep.totalSleepHours)
    }

    private var hoursNeededFormatted: String {
        // Default sleep need - could be personalized
        return formatDuration(7.5)
    }

    private var sleepTip: TipCard? {
        guard let sleep = viewModel.todayMetrics?.sleep else { return nil }

        if sleep.totalSleepHours < 6 {
            return SleepTips.needMoreSleep(deficit: 7.5 - sleep.totalSleepHours)
        } else if sleepPerformance >= 85 {
            return SleepTips.greatJob()
        } else {
            return SleepTips.maintainConsistency()
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.moduleP) {

                // HERO: Large text display (Whoop-style)
                sleepPerformanceHero
                    .padding(.top, Theme.Spacing.moduleP)

                // Sleep Comparison Boxes
                SleepComparisonBoxes(
                    hoursSlept: hoursSleptFormatted,
                    hoursNeeded: hoursNeededFormatted
                )
                .padding(.horizontal, Theme.Spacing.moduleP)

                // Tip Card
                if let tip = sleepTip {
                    tip.padding(.horizontal, Theme.Spacing.moduleP)
                }

                // Sleep Activities
                sleepActivitiesSection
                    .padding(.horizontal, Theme.Spacing.moduleP)

                // Statistics Section (VS. PREVIOUS 30 DAYS)
                statisticsSection
                    .padding(.horizontal, Theme.Spacing.moduleP)

                // What is Sleep Performance?
                WhatIsInfoCardWithImage(
                    title: "What is Sleep Performance?",
                    description: "Discover the science behind good sleep, how it's measured, and how it achieves it.",
                    imageName: "sleep_preview",
                    onTap: { showSleepInfo = true }
                )
                .padding(.horizontal, Theme.Spacing.moduleP)

                // 7-Day Charts Section
                chartsSection
                    .padding(.horizontal, Theme.Spacing.moduleP)
            }
            .padding(.bottom, Theme.Spacing.moduleP)
        }
        .background(Theme.Colors.primary)
        .sheet(isPresented: $showSleepInfo) {
            sleepInfoSheet
        }
    }

    // MARK: - Sleep Performance Hero (Whoop-style - no gauge)

    private var sleepPerformanceHero: some View {
        VStack(spacing: 12) {
            // Header with info button
            HStack {
                Spacer()

                Text("SLEEP")
                    .font(Theme.Fonts.sectionHeader)
                    .tracking(2)
                    .foregroundColor(Theme.Colors.textSecondary)

                Spacer()

                Button(action: { showSleepInfo = true }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
            .padding(.horizontal, 20)

            Text("PERFORMANCE")
                .font(Theme.Fonts.sectionHeader)
                .tracking(2)
                .foregroundColor(Theme.Colors.textSecondary)

            // Large percentage text with striking font
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(sleepPerformance)")
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundColor(Theme.Colors.whoopTeal)
                Text("%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.whoopTeal)
            }

            // Share button
            Button(action: { /* TODO: Share sleep */ }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                    Text("SHARE")
                        .font(Theme.Fonts.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(Theme.Colors.whoopTeal)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.Colors.cardBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Theme.Colors.whoopTeal.opacity(0.5), lineWidth: 1)
                )
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Sleep Activities Section

    @ViewBuilder
    private var sleepActivitiesSection: some View {
        if let sleep = viewModel.todayMetrics?.sleep,
           let bedtime = sleep.bedtime,
           let wakeTime = sleep.wakeTime {
            VStack(alignment: .leading, spacing: 12) {
                Text("SLEEP")
                    .whoopSectionHeader()

                SleepActivityRow(
                    bedtime: formatTime(bedtime),
                    wakeTime: formatTime(wakeTime),
                    duration: formatDuration(sleep.totalSleepHours),
                    quality: nil
                )
            }
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        StatisticsSection(
            title: "SLEEP STATISTICS",
            stats: [
                StatRow(
                    icon: "bed.double.fill",
                    label: "Time in Bed",
                    value: formatDuration(viewModel.todayMetrics?.sleep?.primarySession?.totalDurationHours ?? 0),
                    trend: viewModel.sleepTrend,
                    baseline: viewModel.sevenDayBaseline?.averageSleepDuration.map { formatDuration($0 * 1.1) }
                ),
                StatRow(
                    icon: "clock.fill",
                    label: "Consistency",
                    value: "\(Int(viewModel.todayMetrics?.sleepTimingConsistency ?? 0))%",
                    trend: nil,
                    baseline: nil
                ),
                StatRow(
                    icon: "sparkles",
                    label: "Restorative %",
                    value: "\(calculateRestorativePercentage())%",
                    trend: nil,
                    baseline: nil
                ),
                StatRow(
                    icon: "minus.plus.batteryblock.fill",
                    label: "Sleep Debt",
                    value: formatSleepDebt(viewModel.todayMetrics?.sleepDebt?.debtHours ?? 0),
                    trend: nil,
                    baseline: nil
                )
            ],
            rightLabel: "VS. PREVIOUS 30 DAYS"
        )
    }

    // MARK: - Charts Section

    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.moduleP) {
            // Section Header
            Text("VS. LAST 7 DAYS")
                .whoopSectionHeader()

            // Sleep Performance Bar Chart
            VStack(alignment: .leading, spacing: 8) {
                Text("Sleep Performance")
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.Colors.textPrimary)

                RecoveryBarChart(data: sleepPerformanceChartData)
            }
            .whoopCard()
            .padding(Theme.Dimensions.cardPadding)

            // Hours vs Need Line Chart
            VStack(alignment: .leading, spacing: 8) {
                Text("Hours vs Need")
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.Colors.textPrimary)

                DualLineChart(
                    primaryData: hoursSleptChartData,
                    secondaryData: hoursNeededChartData,
                    primaryLabel: "Hours Slept",
                    secondaryLabel: "Sleep Need"
                )
            }
            .padding(Theme.Dimensions.cardPadding)
            .whoopCard()

            // Time in Bed Bar Chart
            VStack(alignment: .leading, spacing: 8) {
                Text("Time in Bed")
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.Colors.textPrimary)

                VerticalBarChart(
                    data: timeInBedChartData,
                    barColor: Theme.Colors.stageDeep
                )
            }
            .padding(Theme.Dimensions.cardPadding)
            .whoopCard()
        }
    }

    // MARK: - Chart Data

    private var sleepPerformanceChartData: [BarChartData] {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return viewModel.weeklyMetrics.suffix(7).enumerated().map { index, metric in
            let dayLabel = days[index % 7]
            let performance = metric.sleep?.averageEfficiency ?? 0
            return .percentage(label: dayLabel, value: performance)
        }
    }

    private var hoursSleptChartData: [ChartDataPoint] {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return viewModel.weeklyMetrics.suffix(7).enumerated().map { index, metric in
            let dayLabel = days[index % 7]
            return ChartDataPoint(label: dayLabel, value: metric.sleep?.totalSleepHours ?? 0)
        }
    }

    private var hoursNeededChartData: [ChartDataPoint] {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return days.map { ChartDataPoint(label: $0, value: 7.5) }
    }

    private var timeInBedChartData: [BarChartData] {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return viewModel.weeklyMetrics.suffix(7).enumerated().map { index, metric in
            let dayLabel = days[index % 7]
            let hours = metric.sleep?.primarySession?.totalDurationHours ?? 0
            return BarChartData(label: dayLabel, value: hours, formattedValue: formatDuration(hours))
        }
    }

    // MARK: - Sleep Info Sheet

    private var sleepInfoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("What is Sleep Performance?")
                        .font(Theme.Fonts.mediumValue)
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text("Sleep Performance measures how well you slept compared to your sleep need. It takes into account total sleep time, sleep efficiency, and the quality of your sleep stages.")
                        .font(Theme.Fonts.body)
                        .foregroundColor(Theme.Colors.textSecondary)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Factors that affect Sleep Performance:")
                            .font(Theme.Fonts.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.Colors.textPrimary)

                        BulletPoint(text: "Total hours of sleep")
                        BulletPoint(text: "Time spent in restorative sleep stages (Deep + REM)")
                        BulletPoint(text: "Sleep consistency and timing")
                        BulletPoint(text: "Sleep disturbances and awakenings")
                    }
                }
                .padding()
            }
            .background(Theme.Colors.primary)
            .navigationTitle("Sleep Performance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showSleepInfo = false }
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        return "\(h):\(String(format: "%02d", m))"
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func formatSleepDebt(_ hours: Double) -> String {
        if hours <= 0 {
            return "0h"
        }
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        if m > 0 {
            return "\(h)h \(m)m"
        }
        return "\(h)h"
    }

    private func calculateRestorativePercentage() -> Int {
        guard let sleep = viewModel.todayMetrics?.sleep else { return 0 }
        let breakdown = sleep.combinedStageBreakdown
        let restorative = Double(breakdown.deepMinutes + breakdown.remMinutes)
        let total = sleep.totalSleepDuration / 60
        guard total > 0 else { return 0 }
        return Int((restorative / total) * 100)
    }
}

// MARK: - Bullet Point Helper

struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Theme.Colors.whoopTeal)
                .frame(width: 6, height: 6)
                .offset(y: 6)

            Text(text)
                .font(Theme.Fonts.caption)
                .foregroundColor(Theme.Colors.textSecondary)
        }
    }
}

#Preview {
    SleepTab(viewModel: DashboardViewModel(healthKitManager: HealthKitManager()))
        .preferredColorScheme(.dark)
}
