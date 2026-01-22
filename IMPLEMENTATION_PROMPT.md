# Claude Code Implementation Prompt: Whoops Redesign

## Overview

You are implementing a comprehensive redesign of the Whoops iOS app - an Apple Health analytics app that replicates Whoop-style metrics using native HealthKit data. This is a **major refactor** that touches nearly every layer of the application, from data calculations to visual presentation.

**Current State:** The app has gone through 6 development sessions, most recently implementing a "premium gradient" design system with animated circular gauges and tabbed navigation. See `DEVELOPMENT_CONTEXT.md` for full history.

**Target State:** A cleaner, Whoop-aligned design with:
- Simplified visual hierarchy (single-color states, no competing gradients)
- Week-view first approach for sleep data
- Semantic color system tied to physiological states
- Clear metric explanations accessible everywhere
- Robust error/zero-state handling

---

## Phase 1: Core Architecture Refactor

### 1.1 Data Layer Migration

**Goal:** Align the data model with Whoop's conceptual framework.

**File: `Models/DailyMetrics.swift`**

Update the `DailyMetrics` struct to include:

```swift
struct DailyMetrics: Codable, Sendable {
    let date: Date

    // Performance Output (was "strain")
    var performanceOutput: PerformanceOutput?

    // Readiness State (was "recovery")
    var readinessState: ReadinessState?

    // Autonomic Balance
    var autonomicBalance: AutonomicBalance?

    // Sleep Analysis
    var sleepAnalysis: SleepAnalysis?

    // Activity Data
    var activityData: ActivityData?
}

struct PerformanceOutput: Codable, Sendable {
    let totalStrain: Double           // 0-21 scale
    let hrZoneMinutes: [HRZone: Int]  // Minutes per zone
    let workoutDuration: TimeInterval
    let activeEnergy: Double          // kcal
    let workouts: [WorkoutEntry]
}

struct ReadinessState: Codable, Sendable {
    let recoveryScore: Int            // 0-100
    let hrvDeviationMs: Double        // ms above/below baseline
    let rhrDeviationBpm: Double       // bpm above/below baseline
    let sleepQuality: Double          // 0-1 derived from performance
    let previousDayStrain: Double     // Carryover load
}

struct AutonomicBalance: Codable, Sendable {
    let hrv: Double                   // ms
    let hrvBaselineDeviation: Double  // percentage from baseline
    let rhr: Double                   // bpm
    let rhrBaselineDeviation: Double  // percentage from baseline
}

struct SleepAnalysis: Codable, Sendable {
    let totalDuration: TimeInterval
    let hoursNeeded: Double
    let hoursVsNeed: Double           // ratio: actual/target
    let efficiency: Double            // 0-1
    let consistency: Double           // 0-1 (1 - variance)
    let performanceScore: Double      // Calculated score 0-100
    let bedtime: Date
    let wakeTime: Date
    let stages: SleepStages
}

struct SleepStages: Codable, Sendable {
    let deepMinutes: Int
    let remMinutes: Int
    let coreMinutes: Int
    let awakeMinutes: Int
}
```

### 1.2 New Calculation Engines

**File: `Services/Calculations/SleepPerformanceEngine.swift` (NEW)**

```swift
/// Sleep Performance = 0.4×(hours/need) + 0.3×efficiency + 0.3×(1 - consistency_variance)
struct SleepPerformanceEngine {
    static func calculate(
        hoursSlept: Double,
        hoursNeeded: Double,
        efficiency: Double,
        bedtimeVariance: TimeInterval,  // stdev over 7 days
        wakeTimeVariance: TimeInterval
    ) -> SleepPerformance {
        let hoursRatio = min(hoursSlept / hoursNeeded, 1.5)
        let hoursComponent = hoursRatio * 0.4

        let efficiencyComponent = efficiency * 0.3

        // Normalize variance: 0 variance = 1.0, 2hr variance = 0
        let totalVarianceHours = (bedtimeVariance + wakeTimeVariance) / 3600
        let consistencyScore = max(0, 1 - (totalVarianceHours / 4))
        let consistencyComponent = consistencyScore * 0.3

        let performance = (hoursComponent + efficiencyComponent + consistencyComponent) * 100

        return SleepPerformance(
            score: Int(performance.rounded()),
            hoursVsNeed: hoursSlept / hoursNeeded,
            efficiency: efficiency,
            consistency: consistencyScore
        )
    }
}
```

**File: `Services/Calculations/ConsistencyCalculator.swift` (NEW)**

```swift
/// Consistency Variance = stdev(bedtimes) + stdev(wake_times) over 7 days
struct ConsistencyCalculator {
    static func calculate(sleepSessions: [SleepAnalysis]) -> ConsistencyMetrics {
        guard sleepSessions.count >= 3 else {
            return ConsistencyMetrics(
                bedtimeVariance: 0,
                wakeTimeVariance: 0,
                consistencyScore: 1.0,
                insufficientData: true
            )
        }

        let bedtimes = sleepSessions.map { $0.bedtime.timeIntervalSinceReferenceDate }
        let wakeTimes = sleepSessions.map { $0.wakeTime.timeIntervalSinceReferenceDate }

        let bedtimeStdev = standardDeviation(bedtimes)
        let wakeTimeStdev = standardDeviation(wakeTimes)

        // Score: perfect consistency (0 variance) = 100%, 2hr total variance = 0%
        let totalVarianceHours = (bedtimeStdev + wakeTimeStdev) / 3600
        let score = max(0, min(1, 1 - (totalVarianceHours / 4)))

        return ConsistencyMetrics(
            bedtimeVariance: bedtimeStdev,
            wakeTimeVariance: wakeTimeStdev,
            consistencyScore: score,
            insufficientData: false
        )
    }

    private static func standardDeviation(_ values: [Double]) -> Double {
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
}
```

**File: `Services/Calculations/RecoveryScoreEngine.swift` (UPDATE)**

Update the calculation formula to match:
```swift
/// Recovery Score = 0.5×(HRV_deviation_percentile) + 0.3×(1 - RHR_deviation_percentile) + 0.2×sleep_performance
```

Update weights in `Constants.swift`:
```swift
enum RecoveryWeights {
    static let hrvDeviation: Double = 0.50
    static let rhrDeviation: Double = 0.30
    static let sleepPerformance: Double = 0.20
}
```

**File: `Services/Calculations/StrainScoreEngine.swift` (UPDATE)**

```swift
/// Strain = (HR_zone_minutes × intensity_weight) + (active_energy / 100)
struct StrainScoreEngine {
    static let zoneWeights: [HRZone: Double] = [
        .zone1: 0.1,  // Recovery
        .zone2: 0.3,  // Endurance
        .zone3: 0.5,  // Tempo
        .zone4: 0.8,  // Threshold
        .zone5: 1.0   // Max
    ]

    static func calculate(
        hrZoneMinutes: [HRZone: Int],
        activeEnergy: Double
    ) -> StrainScore {
        var weightedMinutes: Double = 0
        for (zone, minutes) in hrZoneMinutes {
            weightedMinutes += Double(minutes) * (zoneWeights[zone] ?? 0)
        }

        let hrComponent = weightedMinutes / 10  // Normalize
        let energyComponent = activeEnergy / 100

        let rawStrain = hrComponent + energyComponent
        let normalizedStrain = min(21, rawStrain)  // Cap at 21

        return StrainScore(
            score: normalizedStrain,
            hrZoneContribution: hrComponent,
            energyContribution: energyComponent,
            zoneBreakdown: hrZoneMinutes
        )
    }
}
```

### 1.3 Week-View Aggregation

**File: `Services/Calculations/WeekAggregator.swift` (NEW)**

```swift
struct WeekAggregator {
    /// Aggregate metrics for calendar week view (not rolling 7-day)
    static func aggregateWeek(
        metrics: [DailyMetrics],
        weekStartDate: Date
    ) -> WeekSummary {
        let calendar = Calendar.current
        let weekDays = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: weekStartDate)
        }

        let weekMetrics = weekDays.compactMap { day in
            metrics.first { calendar.isDate($0.date, inSameDayAs: day) }
        }

        return WeekSummary(
            startDate: weekStartDate,
            days: weekMetrics,
            avgRecovery: average(weekMetrics.compactMap { $0.readinessState?.recoveryScore }),
            avgStrain: average(weekMetrics.compactMap { $0.performanceOutput?.totalStrain }),
            totalSleepHours: weekMetrics.compactMap { $0.sleepAnalysis?.totalDuration }.reduce(0, +) / 3600,
            sleepConsistency: ConsistencyCalculator.calculate(
                sleepSessions: weekMetrics.compactMap { $0.sleepAnalysis }
            )
        )
    }
}
```

---

## Phase 2: Visual System Overhaul

### 2.1 Theme System

**File: `Utilities/Theme.swift` (COMPLETE REWRITE)**

```swift
import SwiftUI

struct Theme {

    // MARK: - Semantic Color System
    struct Colors {
        // Backgrounds
        static let primary = Color(hex: "#000000")      // OLED black
        static let secondary = Color(hex: "#0A0A0A")    // Cards
        static let tertiary = Color(hex: "#1C1C1E")     // Elevated surfaces

        // Text
        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "#A0A0A0")
        static let textTertiary = Color(hex: "#666666")

        // SEMANTIC COLORS - Tied to physiological states
        static let optimal = Color(hex: "#00FF41")      // Green: >80% sleep, HRV up, recovery 70-100
        static let neutral = Color(hex: "#4A9EFF")      // Blue: informational, time-based
        static let caution = Color(hex: "#FF9500")      // Orange: debt accumulating, HRV below baseline
        static let critical = Color(hex: "#FF3B30")     // Red: <60% sleep, high stress

        // NO YELLOW (redundant with orange)
        // NO PURPLE GLOW EFFECTS

        /// Recovery state color
        static func recovery(score: Int) -> Color {
            switch score {
            case 70...100: return optimal
            case 34..<70: return caution
            default: return critical
            }
        }

        /// Strain state color (based on vs target)
        static func strain(current: Double, target: Double) -> Color {
            let ratio = current / target
            if ratio < 0.5 { return neutral }       // Under target
            if ratio < 1.0 { return optimal }       // Approaching target
            if ratio < 1.2 { return caution }       // At/slightly over
            return critical                          // Overreach
        }

        /// HRV deviation color
        static func hrv(deviationPercent: Double) -> Color {
            if deviationPercent >= 10 { return optimal }    // 10%+ above baseline
            if deviationPercent >= -10 { return neutral }   // Within normal range
            if deviationPercent >= -20 { return caution }   // Below baseline
            return critical                                   // Significantly below
        }

        /// Sleep performance color
        static func sleepPerformance(score: Int) -> Color {
            switch score {
            case 80...100: return optimal
            case 60..<80: return neutral
            default: return critical
        }
    }

    // MARK: - Typography (SF Pro)
    struct Fonts {
        /// Hero metrics (76%, 4.3, 108ms)
        static let heroMetric = Font.system(size: 72, weight: .bold, design: .default)

        /// Body text
        static let body = Font.system(size: 17, weight: .regular, design: .default)

        /// Labels (RECOVERY, STRAIN, OVERVIEW)
        static let label = Font.system(size: 13, weight: .semibold, design: .default)

        /// Display numerals (SF Pro Display)
        static func display(_ size: CGFloat) -> Font {
            .system(size: size, weight: .bold, design: .default)
        }

        /// Labels with tracking
        static func label(_ size: CGFloat) -> Font {
            .system(size: size, weight: .semibold, design: .default)
        }
    }

    // MARK: - Spacing System
    struct Spacing {
        static let moduleP: CGFloat = 24    // Module padding
        static let cardGap: CGFloat = 16    // Between cards
        static let inlineGap: CGFloat = 8   // Inline elements
    }
}
```

### 2.2 Component Library

**File: `Views/Components/CircularProgressGauge.swift` (NEW - replaces RecoveryRing)**

Single-metric circular gauge with NO nested rings:

```swift
struct CircularProgressGauge: View {
    let value: Double           // 0-100
    let color: Color
    let label: String
    let sublabel: String?

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Theme.Colors.tertiary, lineWidth: 12)

            // Progress arc
            Circle()
                .trim(from: 0, to: value / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: 4) {
                Text("\(Int(value))%")
                    .font(Theme.Fonts.heroMetric)
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(label.uppercased())
                    .font(Theme.Fonts.label(13))
                    .tracking(1)
                    .foregroundColor(Theme.Colors.textSecondary)

                if let sublabel {
                    Text(sublabel)
                        .font(Theme.Fonts.label(11))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }
        }
        // NO GLOW EFFECTS
    }
}
```

**File: `Views/Components/WeekBarChart.swift` (NEW)**

Horizontal bar chart for sleep timeline:

```swift
struct WeekBarChart: View {
    let sleepData: [DailySleepBar]  // 7 days
    let selectedDay: Date?
    let onDayTap: (Date) -> Void

    struct DailySleepBar: Identifiable {
        let id = UUID()
        let date: Date
        let bedtime: Date
        let wakeTime: Date
        let performanceColor: Color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(sleepData) { day in
                HStack(spacing: 12) {
                    // Day label (Aug 23)
                    Text(day.date.formatted(.dateTime.month(.abbreviated).day()))
                        .font(Theme.Fonts.label(11))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .frame(width: 50, alignment: .leading)

                    // Sleep bar
                    GeometryReader { geo in
                        let startOffset = bedtimeOffset(day.bedtime)
                        let duration = sleepDuration(from: day.bedtime, to: day.wakeTime)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(day.performanceColor)
                            .frame(width: duration * geo.size.width)
                            .offset(x: startOffset * geo.size.width)
                    }
                    .frame(height: 20)
                    .background(Theme.Colors.tertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .contentShape(Rectangle())
                .onTapGesture { onDayTap(day.date) }
            }
        }
    }
}
```

**File: `Views/Components/SegmentedProgressBar.swift` (NEW)**

For sleep stages and metric breakdowns:

```swift
struct SegmentedProgressBar: View {
    let segments: [Segment]

    struct Segment: Identifiable {
        let id = UUID()
        let label: String
        let value: Double       // Percentage of total
        let color: Color
    }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(segments) { segment in
                    Rectangle()
                        .fill(segment.color)
                        .frame(width: geo.size.width * segment.value)
                }
            }
        }
        .frame(height: 8)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
```

**File: `Views/Components/InsightCard.swift` (UPDATE)**

```swift
struct InsightCard: View {
    let icon: String
    let heading: String
    let body: String
    let accentColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(heading)
                    .font(Theme.Fonts.label(15))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(body)
                    .font(Theme.Fonts.body)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(Theme.Spacing.moduleP)
        .background(Theme.Colors.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        // NO GRADIENT BACKGROUNDS
    }
}
```

**File: `Views/Components/MetricTile.swift` (NEW)**

2-column grid tiles:

```swift
struct MetricTile: View {
    let icon: String
    let value: String
    let label: String
    let sublabel: String?
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(Theme.Fonts.display(28))
                .foregroundColor(Theme.Colors.textPrimary)

            Text(label.uppercased())
                .font(Theme.Fonts.label(11))
                .tracking(0.5)
                .foregroundColor(Theme.Colors.textSecondary)

            if let sublabel {
                Text(sublabel)
                    .font(Theme.Fonts.label(10))
                    .foregroundColor(color)
            }
        }
        .padding(Theme.Spacing.cardGap)
        .background(Theme.Colors.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
```

---

## Phase 3: Screen Redesign

### 3.1 Overview Tab

**File: `Views/Dashboard/Tabs/OverviewTab.swift` (REWRITE)**

```swift
struct OverviewTab: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.moduleP) {

                // HERO: Recovery gauge (SINGLE, not dual)
                CircularProgressGauge(
                    value: Double(viewModel.recoveryScore),
                    color: Theme.Colors.recovery(score: viewModel.recoveryScore),
                    label: "Recovery",
                    sublabel: viewModel.recoveryCategory
                )
                .frame(width: 200, height: 200)
                .padding(.top, Theme.Spacing.moduleP)

                // 3-metric tiles (2-column grid)
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Theme.Spacing.cardGap) {

                    MetricTile(
                        icon: "waveform.path.ecg",
                        value: "\(Int(viewModel.hrv))ms",
                        label: "HRV",
                        sublabel: "\(viewModel.hrvDeviationPercent > 0 ? "+" : "")\(Int(viewModel.hrvDeviationPercent))%",
                        color: Theme.Colors.hrv(deviationPercent: viewModel.hrvDeviationPercent)
                    )

                    MetricTile(
                        icon: "heart.fill",
                        value: "\(Int(viewModel.rhr)) bpm",
                        label: "RHR",
                        sublabel: viewModel.rhrTrend,
                        color: Theme.Colors.neutral
                    )

                    MetricTile(
                        icon: "flame.fill",
                        value: String(format: "%.1f", viewModel.todayStrain),
                        label: "Strain",
                        sublabel: nil,
                        color: Theme.Colors.strain(
                            current: viewModel.todayStrain,
                            target: viewModel.optimalStrainTarget
                        )
                    )

                    MetricTile(
                        icon: "bed.double.fill",
                        value: viewModel.sleepDurationFormatted,
                        label: "Sleep",
                        sublabel: "\(viewModel.sleepPerformance)%",
                        color: Theme.Colors.sleepPerformance(score: viewModel.sleepPerformance)
                    )
                }
                .padding(.horizontal, Theme.Spacing.moduleP)

                // Contextual insight
                if let insight = viewModel.primaryInsight {
                    InsightCard(
                        icon: insight.icon,
                        heading: insight.title,
                        body: insight.message,
                        accentColor: insight.color
                    )
                    .padding(.horizontal, Theme.Spacing.moduleP)
                }

                // NO "Start Activity" CTA

                // Activity feed: actual workouts only
                if !viewModel.todayWorkouts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ACTIVITY")
                            .font(Theme.Fonts.label(11))
                            .tracking(1)
                            .foregroundColor(Theme.Colors.textSecondary)

                        ForEach(viewModel.todayWorkouts) { workout in
                            WorkoutRow(workout: workout)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.moduleP)
                }
            }
            .padding(.bottom, Theme.Spacing.moduleP)
        }
        .background(Theme.Colors.primary)
    }
}
```

### 3.2 Sleep Tab

**File: `Views/Dashboard/Tabs/SleepTab.swift` (REWRITE)**

```swift
struct SleepTab: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var selectedDay: Date?

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.moduleP) {

                // Week selector
                WeekSelector(
                    currentWeek: viewModel.selectedWeek,
                    onPreviousWeek: { viewModel.goToPreviousWeek() },
                    onNextWeek: { viewModel.goToNextWeek() }
                )

                // 3-metric summary
                HStack(spacing: Theme.Spacing.cardGap) {
                    SleepMetricBox(
                        value: "\(viewModel.weekSleepPerformance)%",
                        label: "Performance"
                    )
                    SleepMetricBox(
                        value: String(format: "%.1f:%.1f", viewModel.hoursSlept, viewModel.hoursNeeded),
                        label: "Hrs vs Need"
                    )
                    SleepMetricBox(
                        value: viewModel.timeInBedFormatted,
                        label: "Time in Bed"
                    )
                }
                .padding(.horizontal, Theme.Spacing.moduleP)

                // NO efficiency metric - replaced with:
                HStack {
                    Text("CONSISTENCY")
                        .font(Theme.Fonts.label(11))
                        .foregroundColor(Theme.Colors.textSecondary)
                    Spacer()
                    Text("\(Int(viewModel.sleepConsistency * 100))%")
                        .font(Theme.Fonts.display(17))
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                .padding(.horizontal, Theme.Spacing.moduleP)

                // Week bar chart (bedtime-to-wake windows)
                WeekBarChart(
                    sleepData: viewModel.weekSleepBars,
                    selectedDay: selectedDay,
                    onDayTap: { day in
                        selectedDay = day
                    }
                )
                .frame(height: 180)
                .padding(.horizontal, Theme.Spacing.moduleP)

                // If day selected, show stages breakdown
                if let day = selectedDay,
                   let sleepDetail = viewModel.sleepDetail(for: day) {
                    SleepStagesCard(sleep: sleepDetail)
                        .padding(.horizontal, Theme.Spacing.moduleP)
                }

                // Insight card
                if let insight = viewModel.sleepInsight {
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
}
```

### 3.3 Recovery Tab

**File: `Views/Dashboard/Tabs/RecoveryTab.swift` (REWRITE)**

```swift
struct RecoveryTab: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.moduleP) {

                // Hero gauge (same as Overview)
                CircularProgressGauge(
                    value: Double(viewModel.recoveryScore),
                    color: Theme.Colors.recovery(score: viewModel.recoveryScore),
                    label: "Recovery",
                    sublabel: nil
                )
                .frame(width: 180, height: 180)

                // 4 horizontal progress bars (breakdown)
                VStack(spacing: 16) {
                    RecoveryComponentBar(
                        label: "HRV Deviation",
                        value: viewModel.hrvDeviationMs,
                        suffix: "ms",
                        progress: viewModel.hrvComponentProgress,
                        color: Theme.Colors.hrv(deviationPercent: viewModel.hrvDeviationPercent)
                    )

                    RecoveryComponentBar(
                        label: "Resting HR Deviation",
                        value: viewModel.rhrDeviationBpm,
                        suffix: "bpm",
                        progress: viewModel.rhrComponentProgress,
                        color: viewModel.rhrDeviationBpm < 0 ? Theme.Colors.optimal : Theme.Colors.caution
                    )

                    RecoveryComponentBar(
                        label: "Sleep Quality",
                        value: Double(viewModel.sleepPerformance),
                        suffix: "%",
                        progress: Double(viewModel.sleepPerformance) / 100,
                        color: Theme.Colors.sleepPerformance(score: viewModel.sleepPerformance)
                    )

                    RecoveryComponentBar(
                        label: "Previous Day Strain",
                        value: viewModel.previousDayStrain,
                        suffix: "",
                        progress: viewModel.previousDayStrain / 21,
                        color: Theme.Colors.neutral
                    )
                }
                .padding(.horizontal, Theme.Spacing.moduleP)

                // 7-day trend sparkline (REPLACES "VS. PREVIOUS 30 DAYS")
                VStack(alignment: .leading, spacing: 8) {
                    Text("7-DAY TREND")
                        .font(Theme.Fonts.label(11))
                        .foregroundColor(Theme.Colors.textSecondary)

                    SparklineChart(
                        data: viewModel.recoveryTrend7Day,
                        color: Theme.Colors.optimal
                    )
                    .frame(height: 60)
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
}
```

### 3.4 Strain Tab

**File: `Views/Dashboard/Tabs/StrainTab.swift` (REWRITE)**

```swift
struct StrainTab: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.moduleP) {

                // Strain gauge with target ring
                StrainGauge(
                    current: viewModel.todayStrain,
                    target: viewModel.optimalStrainTarget
                )
                .frame(width: 180, height: 180)

                // Raw contribution breakdown (NO POINTS SYSTEM)
                VStack(spacing: 12) {
                    StrainContributionRow(
                        label: "HR Zone Time",
                        value: "\(viewModel.hrZoneTimeMinutes)min"
                    )
                    StrainContributionRow(
                        label: "Workout Duration",
                        value: "\(viewModel.workoutDurationMinutes)min"
                    )
                    StrainContributionRow(
                        label: "Active Energy",
                        value: "\(Int(viewModel.activeEnergy)) cal"
                    )
                }
                .padding(.horizontal, Theme.Spacing.moduleP)

                // HR Zones: FULL WIDTH bars with minutes
                VStack(alignment: .leading, spacing: 12) {
                    Text("HR ZONES")
                        .font(Theme.Fonts.label(11))
                        .foregroundColor(Theme.Colors.textSecondary)

                    ForEach(HRZone.allCases, id: \.self) { zone in
                        HRZoneBar(
                            zone: zone,
                            minutes: viewModel.zoneMinutes[zone] ?? 0,
                            maxMinutes: viewModel.maxZoneMinutes
                        )
                    }
                }
                .padding(.horizontal, Theme.Spacing.moduleP)

                // Workout log
                if !viewModel.todayWorkouts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("WORKOUTS")
                            .font(Theme.Fonts.label(11))
                            .foregroundColor(Theme.Colors.textSecondary)

                        ForEach(viewModel.todayWorkouts) { workout in
                            WorkoutLogEntry(
                                type: workout.type,
                                timestamp: workout.startTime,
                                duration: workout.duration,
                                avgHR: workout.averageHeartRate
                            )
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.moduleP)
                }
            }
            .padding(.vertical, Theme.Spacing.moduleP)
        }
        .background(Theme.Colors.primary)
    }
}
```

---

## Phase 4: Error States & Data Validation

### 4.1 Zero-State Handling

**File: `Views/Components/ZeroStateView.swift` (NEW)**

```swift
struct ZeroStateView: View {
    let metric: MetricType
    let message: String

    static func rhr() -> ZeroStateView {
        ZeroStateView(
            metric: .rhr,
            message: "No resting heart rate data available. Ensure Apple Watch is worn during sleep."
        )
    }

    static func hrv() -> ZeroStateView {
        ZeroStateView(
            metric: .hrv,
            message: "Insufficient data. Requires 4+ hours of sleep with Apple Watch."
        )
    }

    static func noWorkouts() -> ZeroStateView {
        ZeroStateView(
            metric: .strain,
            message: "No activity logged today"
        )
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: metric.icon)
                .font(.system(size: 32))
                .foregroundColor(Theme.Colors.textTertiary)

            Text(message)
                .font(Theme.Fonts.body)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.moduleP)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
```

### 4.2 Data Validation

**File: `Services/DataQuality/DataValidator.swift` (NEW)**

```swift
struct DataValidator {

    struct ValidationResult {
        let isValid: Bool
        let anomalyType: AnomalyType?
        let message: String?
    }

    enum AnomalyType {
        case rhrOutOfRange
        case hrvOutOfRange
        case sensorAnomaly
    }

    /// Validate RHR (physiologically possible: 30-120 bpm)
    static func validateRHR(_ rhr: Double) -> ValidationResult {
        if rhr < 30 || rhr > 120 {
            return ValidationResult(
                isValid: false,
                anomalyType: .rhrOutOfRange,
                message: "Sensor data anomaly detected. Check Apple Watch fit."
            )
        }
        return ValidationResult(isValid: true, anomalyType: nil, message: nil)
    }

    /// Validate HRV (physiologically possible: 10-200 ms)
    static func validateHRV(_ hrv: Double) -> ValidationResult {
        if hrv < 10 || hrv > 200 {
            return ValidationResult(
                isValid: false,
                anomalyType: .hrvOutOfRange,
                message: "Sensor data anomaly detected. Check Apple Watch fit."
            )
        }
        return ValidationResult(isValid: true, anomalyType: nil, message: nil)
    }

    /// Exclude outliers from averages
    static func filterOutliers<T: BinaryFloatingPoint>(
        _ values: [T],
        range: ClosedRange<T>
    ) -> [T] {
        values.filter { range.contains($0) }
    }
}
```

### 4.3 Error Banner Component

**File: `Views/Components/ErrorBanner.swift` (NEW)**

```swift
struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Theme.Colors.caution)

            Text(message)
                .font(Theme.Fonts.body)
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        .padding(Theme.Spacing.cardGap)
        .background(Theme.Colors.secondary)
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundColor(Theme.Colors.caution),
            alignment: .top
        )
    }
}
```

---

## Phase 5: Notifications

### 5.1 Notification Updates

**File: `Services/Notifications/NotificationManager.swift` (UPDATE)**

Replace vague notifications with specific ones:

```swift
extension NotificationManager {

    /// Generate specific insight notification
    func generateInsightNotification(for metrics: DailyMetrics) -> UNNotificationContent? {
        let content = UNMutableNotificationContent()

        // HRV-based insight (SPECIFIC, not vague)
        if let hrv = metrics.autonomicBalance,
           hrv.hrvBaselineDeviation >= 16 {
            content.title = "Elevated HRV"
            content.body = "HRV \(Int(hrv.hrvBaselineDeviation))% above baseline. Consider high-intensity session."
            return content
        }

        // Low recovery suppression
        if let recovery = metrics.readinessState,
           recovery.recoveryScore < 50 {
            content.title = "Low Recovery Detected"
            content.body = "Prioritize rest today. Recovery at \(recovery.recoveryScore)%."
            return content
        }

        return nil
    }

    /// Opt-in bedtime reminder
    func scheduleBedtimeReminder(targetBedtime: Date, enabled: Bool) {
        guard enabled else { return }

        let reminderTime = Calendar.current.date(byAdding: .minute, value: -30, to: targetBedtime)!

        let content = UNMutableNotificationContent()
        content.title = "Bedtime Reminder"
        content.body = "Bedtime in 30 minutes to maintain consistency."

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "bedtime.reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}
```

---

## Phase 6: Information Architecture

### 6.1 Metric Info Sheets

**File: `Views/Components/MetricInfoSheet.swift` (NEW)**

```swift
struct MetricInfoSheet: View {
    let metric: MetricType

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title
                Text(metric.displayName)
                    .font(Theme.Fonts.display(28))
                    .foregroundColor(Theme.Colors.textPrimary)

                // Calculation explanation
                VStack(alignment: .leading, spacing: 8) {
                    Text("HOW IT'S CALCULATED")
                        .font(Theme.Fonts.label(11))
                        .foregroundColor(Theme.Colors.textSecondary)

                    Text(metric.calculationExplanation)
                        .font(Theme.Fonts.body)
                        .foregroundColor(Theme.Colors.textPrimary)
                }

                // Normal ranges
                VStack(alignment: .leading, spacing: 8) {
                    Text("NORMAL RANGES")
                        .font(Theme.Fonts.label(11))
                        .foregroundColor(Theme.Colors.textSecondary)

                    ForEach(metric.ranges, id: \.label) { range in
                        HStack {
                            Circle()
                                .fill(range.color)
                                .frame(width: 8, height: 8)
                            Text(range.label)
                                .font(Theme.Fonts.body)
                                .foregroundColor(Theme.Colors.textPrimary)
                            Spacer()
                            Text(range.valueRange)
                                .font(Theme.Fonts.label(13))
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
                }

                // Actionable guidance
                VStack(alignment: .leading, spacing: 8) {
                    Text("WHAT IT MEANS")
                        .font(Theme.Fonts.label(11))
                        .foregroundColor(Theme.Colors.textSecondary)

                    Text(metric.actionableGuidance)
                        .font(Theme.Fonts.body)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
            }
            .padding(Theme.Spacing.moduleP)
        }
        .background(Theme.Colors.primary)
    }
}

// Example for HRV:
extension MetricType {
    var actionableGuidance: String {
        switch self {
        case .hrv:
            return "Heart Rate Variability measures time between heartbeats. Higher values (>60ms) indicate better stress resilience. Impacted by sleep, alcohol, illness."
        // ... other cases
        }
    }
}
```

### 6.2 Date Picker Navigation

**File: `Views/Dashboard/DatePickerHeader.swift` (NEW)**

```swift
struct DatePickerHeader: View {
    @Binding var selectedDate: Date
    @State private var showDatePicker = false

    var body: some View {
        HStack {
            Button(action: { showDatePicker.toggle() }) {
                HStack(spacing: 8) {
                    Text(selectedDate.isToday ? "TODAY" : selectedDate.formatted(.dateTime.month().day()))
                        .font(Theme.Fonts.label(15))
                        .foregroundColor(Theme.Colors.textPrimary)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }

            Spacer()
        }
        .sheet(isPresented: $showDatePicker) {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .presentationDetents([.medium])
        }
    }
}
```

### 6.3 CSV Export

**File: `Services/Persistence/ExportService.swift` (UPDATE)**

```swift
extension ExportService {

    /// Export weekly summary with all raw metrics
    func exportWeeklyCSV(weekStart: Date) async throws -> URL {
        let weekMetrics = try await fetchWeekMetrics(from: weekStart)

        var csv = "Date,Recovery,Strain,HRV,RHR,Sleep Hours,Sleep Performance,Consistency\n"

        for metric in weekMetrics {
            let date = metric.date.formatted(.iso8601.day().month().year())
            let recovery = metric.readinessState?.recoveryScore ?? 0
            let strain = metric.performanceOutput?.totalStrain ?? 0
            let hrv = metric.autonomicBalance?.hrv ?? 0
            let rhr = metric.autonomicBalance?.rhr ?? 0
            let sleepHours = (metric.sleepAnalysis?.totalDuration ?? 0) / 3600
            let sleepPerf = metric.sleepAnalysis?.performanceScore ?? 0
            let consistency = metric.sleepAnalysis?.consistency ?? 0

            csv += "\(date),\(recovery),\(String(format: "%.1f", strain)),\(Int(hrv)),\(Int(rhr)),\(String(format: "%.1f", sleepHours)),\(Int(sleepPerf)),\(Int(consistency * 100))\n"
        }

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("whoops_week_\(weekStart.formatted(.iso8601)).csv")

        try csv.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}
```

---

## Phase 7: Accessibility & Performance

### 7.1 VoiceOver Labels

Add accessibility labels to all gauges:

```swift
CircularProgressGauge(...)
    .accessibilityLabel("Recovery: \(Int(value)) percent, \(category)")
    .accessibilityHint("Double tap for recovery details")
```

### 7.2 Dynamic Type Support

Ensure all text uses Dynamic Type:

```swift
extension Theme.Fonts {
    static func dynamicBody(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .default)
            .dynamicTypeSize(.small ... .accessibility5)
    }
}
```

### 7.3 Reduce Motion

**File: `Views/Modifiers/ReduceMotionModifier.swift` (NEW)**

```swift
struct ReduceMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? nil : .default, value: true)
    }
}

// Disable glow animations when reduce motion enabled
extension View {
    func conditionalGlow(color: Color, enabled: Bool) -> some View {
        Group {
            if enabled {
                self.glow(color: color, radius: 10, opacity: 0.3)
            } else {
                self
            }
        }
    }
}
```

### 7.4 HealthKit Caching

**File: `Services/HealthKit/HealthKitCache.swift` (NEW)**

```swift
actor HealthKitCache {
    static let shared = HealthKitCache()

    private var cache: [String: (data: Any, timestamp: Date)] = [:]
    private let maxAge: TimeInterval = 300  // 5 minutes

    func get<T>(key: String) -> T? {
        guard let entry = cache[key],
              Date().timeIntervalSince(entry.timestamp) < maxAge else {
            return nil
        }
        return entry.data as? T
    }

    func set<T>(key: String, value: T) {
        cache[key] = (data: value, timestamp: Date())
    }

    func invalidate() {
        cache.removeAll()
    }
}

// In HealthKitManager:
extension HealthKitManager {
    func fetchWithCache<T>(
        key: String,
        fetch: () async throws -> T
    ) async throws -> T {
        if let cached: T = await HealthKitCache.shared.get(key: key) {
            return cached
        }

        let data = try await fetch()
        await HealthKitCache.shared.set(key: key, value: data)
        return data
    }
}
```

---

## Edge Cases to Handle

### First-Time User
- Show onboarding explaining required permissions
- Display "3-day calibration period" message
- Gray out scores until baseline established

### Watch Not Worn
- Detect via missing HR data during expected sleep window
- Display setup prompt, not broken UI

### Multiple Sleep Sessions (Naps)
- Aggregate into total sleep duration
- Show breakdown in sleep detail view

### Manual Workout Entry
- Accept strain contribution even without HR data
- Use estimated calorie burn for strain calculation

---

## Files to Delete

Remove these legacy components that are being replaced:

- `Views/Components/RecoveryRing.swift` (replaced by `CircularProgressGauge`)
- `Views/Components/StrainArc.swift` (replaced by `StrainGauge`)
- `Views/Components/BiometricSatellite.swift` (replaced by `MetricTile`)

---

## Testing Checklist

Before considering this complete:

1. [ ] Recovery score matches formula: 0.5×HRV + 0.3×RHR + 0.2×Sleep
2. [ ] Sleep performance matches formula: 0.4×hours + 0.3×efficiency + 0.3×consistency
3. [ ] Week view shows calendar week, not rolling 7 days
4. [ ] All colors match semantic meaning (green=optimal, blue=neutral, orange=caution, red=critical)
5. [ ] NO yellow or purple anywhere in the UI
6. [ ] Zero states display proper messages, not broken UI
7. [ ] Info button on each metric opens explanation sheet
8. [ ] Historical data accessible via date picker
9. [ ] CSV export works for weekly summary
10. [ ] VoiceOver reads all gauges correctly
11. [ ] App works offline with cached data
12. [ ] No "0 bpm" or missing data shown in UI

---

## Important Implementation Notes

1. **Swift 6 Concurrency**: This project uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Follow patterns in `CLAUDE.md` for Codable conformance.

2. **SwiftData Predicates**: Capture variables before `#Predicate` closures. `hasPrefix` not supported - filter in memory.

3. **Import Requirements**: Files using `@Published`, `@StateObject` need `import Combine`.

4. **NavigationStack**: Use `navigationDestination(for:)` pattern established in Session 4.

5. **No Breaking Changes**: Maintain backward compatibility with existing SwiftData records.
