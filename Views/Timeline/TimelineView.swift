import SwiftUI
import Combine
import SwiftData

// MARK: - Brutalist Timeline
// Raw data history. Hard edges. Industrial grid.

struct TimelineView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = TimelineViewModel()

    @State private var selectedDay: DailyMetrics?
    @State private var isCompareMode = false
    @State private var compareFirstDay: DailyMetrics?
    @State private var compareSecondDay: DailyMetrics?
    @State private var showingComparison = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.void.ignoresSafeArea()

                Group {
                    if viewModel.isLoading && viewModel.dailyMetrics.isEmpty {
                        loadingView
                    } else if viewModel.dailyMetrics.isEmpty {
                        emptyView
                    } else {
                        timelineList
                    }
                }
            }
            .navigationTitle("TIMELINE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.void, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if isCompareMode {
                            isCompareMode = false
                            compareFirstDay = nil
                            compareSecondDay = nil
                        } else {
                            isCompareMode = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isCompareMode ? "xmark" : "arrow.left.arrow.right")
                                .font(.system(size: 14, weight: .bold))
                            if isCompareMode {
                                Text("CANCEL")
                                    .font(Theme.Fonts.label(size: 10))
                                    .tracking(1)
                            }
                        }
                        .foregroundColor(isCompareMode ? Theme.Colors.rust : Theme.Colors.bone)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            viewModel.timeRange = .week
                        } label: {
                            Label("7 DAYS", systemImage: viewModel.timeRange == .week ? "checkmark" : "")
                        }

                        Button {
                            viewModel.timeRange = .month
                        } label: {
                            Label("28 DAYS", systemImage: viewModel.timeRange == .month ? "checkmark" : "")
                        }

                        Button {
                            viewModel.timeRange = .quarter
                        } label: {
                            Label("90 DAYS", systemImage: viewModel.timeRange == .quarter ? "checkmark" : "")
                        }
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundColor(Theme.Colors.bone)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if isCompareMode {
                    comparisonSelectionBar
                }
            }
            .refreshable {
                await viewModel.loadData(healthKitManager: healthKitManager, modelContext: modelContext)
            }
            .sheet(item: $selectedDay) { day in
                DayDetailView(metrics: day, baseline: viewModel.baseline)
            }
            .sheet(isPresented: $showingComparison) {
                if let first = compareFirstDay, let second = compareSecondDay {
                    ComparisonView(
                        leftMetrics: first.date < second.date ? first : second,
                        rightMetrics: first.date < second.date ? second : first,
                        baseline: viewModel.baseline
                    )
                }
            }
        }
        .task {
            await viewModel.loadData(healthKitManager: healthKitManager, modelContext: modelContext)
        }
    }

    // MARK: - Comparison Selection Bar

    private var comparisonSelectionBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.Colors.graphite)
                .frame(height: 1)

            HStack(spacing: Theme.Spacing.md) {
                daySlot(day: compareFirstDay, label: "1ST", slotNumber: 1)

                Text("VS")
                    .font(Theme.Fonts.mono(size: 12))
                    .foregroundColor(Theme.Colors.chalk)

                daySlot(day: compareSecondDay, label: "2ND", slotNumber: 2)

                Spacer()

                Button {
                    showingComparison = true
                } label: {
                    Text("COMPARE")
                        .font(Theme.Fonts.mono(size: 12))
                        .tracking(1)
                        .foregroundColor(Theme.Colors.void)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(
                            (compareFirstDay != nil && compareSecondDay != nil)
                            ? Theme.Colors.bone
                            : Theme.Colors.ash
                        )
                }
                .disabled(compareFirstDay == nil || compareSecondDay == nil)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.concrete)
        }
    }

    private func daySlot(day: DailyMetrics?, label: String, slotNumber: Int) -> some View {
        VStack(spacing: 2) {
            if let day = day {
                Text(day.date.formatted(.dateTime.month(.abbreviated).day()).uppercased())
                    .font(Theme.Fonts.mono(size: 12))
                    .foregroundColor(Theme.Colors.bone)

                Button {
                    if slotNumber == 1 {
                        compareFirstDay = nil
                    } else {
                        compareSecondDay = nil
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.Colors.rust)
                }
            } else {
                Text(label)
                    .font(Theme.Fonts.label(size: 10))
                    .foregroundColor(Theme.Colors.chalk)
                    .tracking(1)

                Text("TAP DAY")
                    .font(Theme.Fonts.label(size: 8))
                    .foregroundColor(Theme.Colors.ash)
            }
        }
        .frame(width: 70)
        .padding(.vertical, Theme.Spacing.sm)
        .background(day != nil ? Theme.Colors.steel : Theme.Colors.concrete)
        .brutalistBorder(day != nil ? Theme.Colors.bone : Theme.Colors.graphite)
    }

    private func handleDayTap(_ day: DailyMetrics) {
        if isCompareMode {
            if compareFirstDay == nil {
                compareFirstDay = day
            } else if compareSecondDay == nil {
                if day.id != compareFirstDay?.id {
                    compareSecondDay = day
                }
            } else {
                compareSecondDay = day
            }
        } else {
            selectedDay = day
        }
    }

    // MARK: - Timeline List

    private var timelineList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(groupedByWeek, id: \.0) { weekStart, days in
                    Section {
                        ForEach(days) { day in
                            DayRow(
                                metrics: day,
                                isSelected: isCompareMode && (compareFirstDay?.id == day.id || compareSecondDay?.id == day.id),
                                selectionNumber: selectionNumber(for: day)
                            )
                            .onTapGesture { handleDayTap(day) }

                            Rectangle()
                                .fill(Theme.Colors.graphite)
                                .frame(height: 1)
                                .padding(.leading, 60)
                        }
                    } header: {
                        weekHeader(weekStart)
                    }
                }

                if viewModel.isLoading {
                    ProgressView()
                        .tint(Theme.Colors.bone)
                        .padding()
                }
            }
        }
    }

    // MARK: - Week Header

    private func weekHeader(_ startDate: Date) -> some View {
        HStack {
            Text(weekRangeString(from: startDate))
                .font(Theme.Fonts.mono(size: 11))
                .foregroundColor(Theme.Colors.chalk)
                .tracking(1)

            Spacer()

            if let weekSummary = viewModel.weekSummary(for: startDate) {
                HStack(spacing: Theme.Spacing.sm) {
                    if let avgRecovery = weekSummary.averageRecovery {
                        HStack(spacing: 2) {
                            Text("R")
                                .font(Theme.Fonts.mono(size: 10))
                            Text("\(avgRecovery)")
                                .font(Theme.Fonts.mono(size: 10))
                        }
                        .foregroundColor(Theme.Colors.bone)
                    }

                    if let avgStrain = weekSummary.averageStrain {
                        HStack(spacing: 2) {
                            Text("S")
                                .font(Theme.Fonts.mono(size: 10))
                            Text("\(avgStrain)")
                                .font(Theme.Fonts.mono(size: 10))
                        }
                        .foregroundColor(avgStrain >= 67 ? Theme.Colors.rust : Theme.Colors.chalk)
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.steel)
    }

    // MARK: - Supporting Views

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .tint(Theme.Colors.bone)
            Text("LOADING...")
                .font(Theme.Fonts.mono(size: 12))
                .foregroundColor(Theme.Colors.chalk)
                .tracking(2)
        }
    }

    private var emptyView: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 32))
                .foregroundColor(Theme.Colors.chalk)

            Text("NO DATA")
                .font(Theme.Fonts.header(size: 18))
                .foregroundColor(Theme.Colors.bone)

            Text("WEAR APPLE WATCH TO COLLECT DATA")
                .font(Theme.Fonts.mono(size: 11))
                .foregroundColor(Theme.Colors.chalk)
                .tracking(1)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Helpers

    private var groupedByWeek: [(Date, [DailyMetrics])] {
        let grouped = Dictionary(grouping: viewModel.dailyMetrics) { metrics in
            DateHelpers.startOfWeek(metrics.date)
        }
        return grouped.sorted { $0.key > $1.key }.map { ($0.key, $0.value.sorted { $0.date > $1.date }) }
    }

    private func weekRangeString(from startDate: Date) -> String {
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: startDate)!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startDate).uppercased()) — \(formatter.string(from: endDate).uppercased())"
    }

    private func selectionNumber(for day: DailyMetrics) -> Int? {
        if compareFirstDay?.id == day.id { return 1 }
        if compareSecondDay?.id == day.id { return 2 }
        return nil
    }
}

// MARK: - Day Row

struct DayRow: View {
    let metrics: DailyMetrics
    var isSelected: Bool = false
    var selectionNumber: Int? = nil

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Date column
            ZStack {
                VStack(spacing: 0) {
                    Text(dayOfWeek)
                        .font(Theme.Fonts.label(size: 9))
                        .foregroundColor(isSelected ? Theme.Colors.bone : Theme.Colors.chalk)
                        .tracking(1)

                    Text(dayNumber)
                        .font(Theme.Fonts.display(size: 24))
                        .foregroundColor(isSelected ? Theme.Colors.bone : Theme.Colors.bone)
                }

                if let number = selectionNumber {
                    Text("\(number)")
                        .font(Theme.Fonts.mono(size: 9))
                        .foregroundColor(Theme.Colors.void)
                        .frame(width: 14, height: 14)
                        .background(Theme.Colors.bone)
                        .offset(x: 16, y: -10)
                }
            }
            .frame(width: 44)

            // Scores row
            HStack(spacing: Theme.Spacing.md) {
                scoreCell(
                    label: "R",
                    value: metrics.recoveryScore?.score,
                    isCritical: (metrics.recoveryScore?.score ?? 100) <= 33
                )

                scoreCell(
                    label: "S",
                    value: metrics.strainScore?.score,
                    isCritical: (metrics.strainScore?.score ?? 0) >= 67
                )

                if let sleep = metrics.sleep?.totalSleepHours {
                    VStack(spacing: 0) {
                        Text("SLP")
                            .font(Theme.Fonts.label(size: 8))
                            .foregroundColor(Theme.Colors.ash)

                        Text(formatHours(sleep))
                            .font(Theme.Fonts.mono(size: 12))
                            .foregroundColor(Theme.Colors.chalk)
                    }
                }
            }

            Spacer()

            if metrics.dataQuality.hasGaps {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.Colors.rust)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Theme.Colors.ash)
        }
        .padding(Theme.Spacing.md)
        .background(
            isSelected ? Theme.Colors.steel :
            (metrics.date.isToday ? Theme.Colors.concrete : Theme.Colors.void)
        )
    }

    private func scoreCell(label: String, value: Int?, isCritical: Bool) -> some View {
        VStack(spacing: 0) {
            Text(label)
                .font(Theme.Fonts.label(size: 8))
                .foregroundColor(Theme.Colors.ash)

            if let score = value {
                Text("\(score)")
                    .font(Theme.Fonts.mono(size: 14))
                    .foregroundColor(isCritical ? Theme.Colors.rust : Theme.Colors.bone)
            } else {
                Text("--")
                    .font(Theme.Fonts.mono(size: 14))
                    .foregroundColor(Theme.Colors.ash)
            }
        }
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: metrics.date).uppercased()
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: metrics.date)
    }

    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)H\(m)M"
    }
}

// MARK: - Day Detail View

struct DayDetailView: View {
    let metrics: DailyMetrics
    let baseline: Baseline?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.void.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Date header
                        VStack(spacing: 2) {
                            Text(metrics.date.formattedDate.uppercased())
                                .font(Theme.Fonts.header(size: 18))
                                .foregroundColor(Theme.Colors.bone)

                            Text(metrics.date.relativeDescription.uppercased())
                                .font(Theme.Fonts.mono(size: 11))
                                .foregroundColor(Theme.Colors.chalk)
                                .tracking(1)
                        }
                        .padding(.top)

                        // Main scores
                        HStack(spacing: Theme.Spacing.md) {
                            if let recovery = metrics.recoveryScore {
                                scoreBlock(
                                    label: "RECOVERY",
                                    score: recovery.score,
                                    category: recovery.category.rawValue,
                                    isCritical: recovery.score <= 33
                                )
                            }

                            if let strain = metrics.strainScore {
                                scoreBlock(
                                    label: "STRAIN",
                                    score: strain.score,
                                    category: strain.category.rawValue,
                                    isCritical: strain.score >= 67
                                )
                            }
                        }

                        // Metrics grid
                        metricsSection

                        // Sleep
                        if let sleep = metrics.sleep {
                            sleepSection(sleep)
                        }

                        // HR Zones
                        if let zones = metrics.zoneDistribution, zones.totalMinutes > 0 {
                            hrZonesSection(zones)
                        }

                        // Workouts
                        if let workouts = metrics.workouts, workouts.totalWorkouts > 0 {
                            workoutsSection(workouts)
                        }

                        // Activity
                        if let activity = metrics.activity {
                            activitySection(activity)
                        }

                        // Data quality
                        dataQualitySection(metrics.dataQuality)
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .navigationTitle("DETAIL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.void, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("DONE") { dismiss() }
                        .font(Theme.Fonts.mono(size: 12))
                        .foregroundColor(Theme.Colors.bone)
                }
            }
        }
    }

    private func scoreBlock(label: String, score: Int, category: String, isCritical: Bool) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(label)
                .font(Theme.Fonts.label(size: 10))
                .foregroundColor(Theme.Colors.chalk)
                .tracking(2)

            Text("\(score)")
                .font(Theme.Fonts.display(size: 48))
                .foregroundColor(isCritical ? Theme.Colors.rust : Theme.Colors.bone)

            Text(category.uppercased())
                .font(Theme.Fonts.mono(size: 10))
                .foregroundColor(Theme.Colors.chalk)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.concrete)
        .brutalistBorder(isCritical ? Theme.Colors.rust : Theme.Colors.graphite)
    }

    private var metricsSection: some View {
        HStack(spacing: Theme.Spacing.sm) {
            if let hrv = metrics.hrv?.nightlySDNN ?? metrics.hrv?.averageSDNN {
                metricCell(label: "HRV", value: "\(Int(hrv))", unit: "MS")
            }

            if let rhr = metrics.heartRate?.restingBPM {
                metricCell(label: "RHR", value: "\(Int(rhr))", unit: "BPM")
            }
        }
    }

    private func metricCell(label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(label)
                .font(Theme.Fonts.label(size: 9))
                .foregroundColor(Theme.Colors.ash)
                .tracking(1)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(Theme.Fonts.mono(size: 20))
                    .foregroundColor(Theme.Colors.bone)

                Text(unit)
                    .font(Theme.Fonts.label(size: 9))
                    .foregroundColor(Theme.Colors.chalk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.steel)
        .brutalistBorder()
    }

    // MARK: - Sleep Section

    private func sleepSection(_ sleep: DailySleepSummary) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("SLEEP")

            HStack(spacing: Theme.Spacing.sm) {
                metricCell(label: "DURATION", value: formatHours(sleep.totalSleepHours), unit: "")
                metricCell(label: "EFFICIENCY", value: "\(Int(sleep.averageEfficiency))", unit: "%")
            }

            // Stages
            VStack(spacing: Theme.Spacing.xs) {
                stageBar("DEEP", pct: sleep.combinedStageBreakdown.deepPercentage)
                stageBar("CORE", pct: sleep.combinedStageBreakdown.corePercentage)
                stageBar("REM", pct: sleep.combinedStageBreakdown.remPercentage)
            }
            .padding(Theme.Spacing.sm)
            .background(Theme.Colors.steel)
            .brutalistBorder()
        }
    }

    private func stageBar(_ name: String, pct: Double) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text(name)
                .font(Theme.Fonts.label(size: 9))
                .foregroundColor(Theme.Colors.chalk)
                .frame(width: 40, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.Colors.graphite)
                    Rectangle()
                        .fill(Theme.Colors.bone)
                        .frame(width: geo.size.width * CGFloat(pct) / 100)
                }
            }
            .frame(height: 6)

            Text("\(Int(pct))%")
                .font(Theme.Fonts.mono(size: 10))
                .foregroundColor(Theme.Colors.chalk)
                .frame(width: 35, alignment: .trailing)
        }
    }

    // MARK: - HR Zones Section

    private func hrZonesSection(_ zones: ZoneTimeDistribution) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("HR ZONES")

            VStack(spacing: Theme.Spacing.xs) {
                zoneRow("Z1", minutes: zones.zone1Minutes)
                zoneRow("Z2", minutes: zones.zone2Minutes)
                zoneRow("Z3", minutes: zones.zone3Minutes)
                zoneRow("Z4", minutes: zones.zone4Minutes)
                zoneRow("Z5", minutes: zones.zone5Minutes, isCritical: true)

                Rectangle()
                    .fill(Theme.Colors.graphite)
                    .frame(height: 1)

                HStack {
                    Text("TOTAL")
                        .font(Theme.Fonts.label(size: 10))
                        .foregroundColor(Theme.Colors.chalk)
                    Spacer()
                    Text("\(zones.totalMinutes) MIN")
                        .font(Theme.Fonts.mono(size: 12))
                        .foregroundColor(Theme.Colors.bone)
                }
            }
            .padding(Theme.Spacing.sm)
            .background(Theme.Colors.steel)
            .brutalistBorder()
        }
    }

    private func zoneRow(_ name: String, minutes: Int, isCritical: Bool = false) -> some View {
        HStack {
            Text(name)
                .font(Theme.Fonts.mono(size: 10))
                .foregroundColor(Theme.Colors.chalk)

            Spacer()

            Text("\(minutes) MIN")
                .font(Theme.Fonts.mono(size: 10))
                .foregroundColor(isCritical && minutes > 0 ? Theme.Colors.rust : Theme.Colors.bone)
        }
    }

    // MARK: - Workouts Section

    private func workoutsSection(_ workouts: DailyWorkoutSummary) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("WORKOUTS (\(workouts.totalWorkouts))")

            ForEach(workouts.workouts) { workout in
                HStack {
                    Image(systemName: workout.activityType.icon)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.rust)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 0) {
                        Text(workout.activityType.rawValue.uppercased())
                            .font(Theme.Fonts.mono(size: 11))
                            .foregroundColor(Theme.Colors.bone)

                        Text(workout.formattedDuration)
                            .font(Theme.Fonts.label(size: 9))
                            .foregroundColor(Theme.Colors.chalk)
                    }

                    Spacer()

                    if let energy = workout.totalEnergyBurned {
                        Text("\(Int(energy)) KCAL")
                            .font(Theme.Fonts.mono(size: 10))
                            .foregroundColor(Theme.Colors.chalk)
                    }
                }
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.steel)
                .brutalistBorder()
            }
        }
    }

    // MARK: - Activity Section

    private func activitySection(_ activity: DailyActivitySummary) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("ACTIVITY")

            HStack(spacing: Theme.Spacing.sm) {
                metricCell(label: "STEPS", value: "\(activity.steps)", unit: "")
                metricCell(label: "ACTIVE", value: "\(Int(activity.activeEnergy))", unit: "KCAL")
            }
        }
    }

    // MARK: - Data Quality Section

    private func dataQualitySection(_ quality: DataQualityIndicator) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("DATA QUALITY")

            HStack(spacing: Theme.Spacing.sm) {
                qualityCell("HR", quality.heartRateCompleteness)
                qualityCell("HRV", quality.hrvCompleteness)
                qualityCell("SLP", quality.sleepCompleteness)
                qualityCell("ACT", quality.activityCompleteness)
            }
        }
    }

    private func qualityCell(_ label: String, _ completeness: Double) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("\(Int(completeness * 100))%")
                .font(Theme.Fonts.mono(size: 12))
                .foregroundColor(completeness >= 0.75 ? Theme.Colors.bone : Theme.Colors.rust)

            Text(label)
                .font(Theme.Fonts.label(size: 8))
                .foregroundColor(Theme.Colors.ash)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.steel)
        .brutalistBorder()
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Theme.Fonts.label(size: 10))
            .foregroundColor(Theme.Colors.chalk)
            .tracking(2)
    }

    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)H \(m)M"
    }
}

// MARK: - Legacy ScoreCard (kept for compatibility)

struct ScoreCard: View {
    let title: String
    let score: Int
    let category: String
    let color: Color

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(title.uppercased())
                .font(Theme.Fonts.label(size: 10))
                .foregroundColor(Theme.Colors.chalk)

            Text("\(score)")
                .font(Theme.Fonts.display(size: 32))
                .foregroundColor(Theme.Colors.bone)

            Text(category.uppercased())
                .font(Theme.Fonts.mono(size: 9))
                .foregroundColor(Theme.Colors.chalk)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.concrete)
        .brutalistBorder()
    }
}

#Preview {
    TimelineView()
        .environmentObject(HealthKitManager())
}
