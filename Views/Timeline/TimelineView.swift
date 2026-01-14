import SwiftUI
import Combine
import SwiftData

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
            Group {
                if viewModel.isLoading && viewModel.dailyMetrics.isEmpty {
                    loadingView
                } else if viewModel.dailyMetrics.isEmpty {
                    emptyView
                } else {
                    timelineList
                }
            }
            .navigationTitle("Timeline")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if isCompareMode {
                            // Exit compare mode
                            isCompareMode = false
                            compareFirstDay = nil
                            compareSecondDay = nil
                        } else {
                            isCompareMode = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isCompareMode ? "xmark.circle.fill" : "arrow.left.arrow.right")
                            if isCompareMode {
                                Text("Cancel")
                                    .font(.subheadline)
                            }
                        }
                        .foregroundColor(isCompareMode ? .red : Theme.Colors.neonTeal)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            viewModel.timeRange = .week
                        } label: {
                            Label("Last 7 Days", systemImage: viewModel.timeRange == .week ? "checkmark" : "")
                        }

                        Button {
                            viewModel.timeRange = .month
                        } label: {
                            Label("Last 28 Days", systemImage: viewModel.timeRange == .month ? "checkmark" : "")
                        }

                        Button {
                            viewModel.timeRange = .quarter
                        } label: {
                            Label("Last 90 Days", systemImage: viewModel.timeRange == .quarter ? "checkmark" : "")
                        }
                    } label: {
                        Image(systemName: "calendar")
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
            Divider()

            HStack(spacing: 16) {
                // First day slot
                daySlot(day: compareFirstDay, label: "1st Day", slotNumber: 1)

                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(Theme.Colors.textGray)
                    .font(.system(size: 14))

                // Second day slot
                daySlot(day: compareSecondDay, label: "2nd Day", slotNumber: 2)

                Spacer()

                // Compare button
                Button {
                    showingComparison = true
                } label: {
                    Text("Compare")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            (compareFirstDay != nil && compareSecondDay != nil)
                            ? Theme.Colors.neonTeal
                            : Theme.Colors.textGray
                        )
                        .cornerRadius(8)
                }
                .disabled(compareFirstDay == nil || compareSecondDay == nil)
            }
            .padding()
            .background(Theme.Colors.panelGray)
        }
    }

    private func daySlot(day: DailyMetrics?, label: String, slotNumber: Int) -> some View {
        VStack(spacing: 2) {
            if let day = day {
                Text(day.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(Theme.Fonts.tensor(size: 14))
                    .foregroundColor(.white)

                Button {
                    if slotNumber == 1 {
                        compareFirstDay = nil
                    } else {
                        compareSecondDay = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textGray)
                }
            } else {
                Text(label)
                    .font(Theme.Fonts.label(size: 12))
                    .foregroundColor(Theme.Colors.textGray)

                Text("Tap a day")
                    .font(Theme.Fonts.label(size: 10))
                    .foregroundColor(Theme.Colors.textGray.opacity(0.6))
            }
        }
        .frame(width: 70)
        .padding(.vertical, 8)
        .background(day != nil ? Theme.Colors.neonTeal.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(day != nil ? Theme.Colors.neonTeal : Theme.Colors.textGray.opacity(0.3), lineWidth: 1)
        )
    }

    private func handleDayTap(_ day: DailyMetrics) {
        if isCompareMode {
            // In compare mode, add to selection
            if compareFirstDay == nil {
                compareFirstDay = day
            } else if compareSecondDay == nil {
                if day.id != compareFirstDay?.id {
                    compareSecondDay = day
                }
            } else {
                // Both slots full - replace second
                compareSecondDay = day
            }
        } else {
            // Normal mode - show detail
            selectedDay = day
        }
    }

    // MARK: - Timeline List

    private var timelineList: some View {
        ScrollView {
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

                            if day.id != days.last?.id {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    } header: {
                        weekHeader(weekStart)
                    }
                }

                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
            }
        }
    }

    // MARK: - Week Header

    private func weekHeader(_ startDate: Date) -> some View {
        HStack {
            Text(weekRangeString(from: startDate))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Spacer()

            // Week summary
            if let weekSummary = viewModel.weekSummary(for: startDate) {
                HStack(spacing: 8) {
                    if let avgRecovery = weekSummary.averageRecovery {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up.heart")
                                .font(.caption2)
                            Text("\(avgRecovery)")
                                .font(.caption)
                        }
                        .foregroundColor(.green)
                    }

                    if let avgStrain = weekSummary.averageStrain {
                        HStack(spacing: 2) {
                            Image(systemName: "flame")
                                .font(.caption2)
                            Text("\(avgStrain)")
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Supporting Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading timeline...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No Data Available")
                .font(.headline)

            Text("Start wearing your Apple Watch to begin collecting health data.")
                .font(.subheadline)
                .foregroundColor(.secondary)
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

        let startStr = formatter.string(from: startDate)
        let endStr = formatter.string(from: endDate)

        return "\(startStr) - \(endStr)"
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
        HStack(spacing: 12) {
            // Date column with selection indicator
            ZStack {
                VStack(spacing: 2) {
                    Text(dayOfWeek)
                        .font(.caption)
                        .foregroundColor(isSelected ? Theme.Colors.neonTeal : .secondary)

                    Text(dayNumber)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? Theme.Colors.neonTeal : .primary)
                }

                if let number = selectionNumber {
                    Text("\(number)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(Theme.Colors.neonTeal)
                        .clipShape(Circle())
                        .offset(x: 18, y: -12)
                }
            }
            .frame(width: 44)

            // Scores
            HStack(spacing: 16) {
                // Recovery
                scoreIndicator(
                    value: metrics.recoveryScore?.score,
                    icon: "arrow.up.heart.fill",
                    color: recoveryColor
                )

                // Strain
                scoreIndicator(
                    value: metrics.strainScore?.score,
                    icon: "flame.fill",
                    color: strainColor
                )

                // Sleep
                if let sleep = metrics.sleep?.totalSleepHours {
                    VStack(spacing: 2) {
                        Image(systemName: "bed.double.fill")
                            .font(.caption)
                            .foregroundColor(.purple)

                        Text(formatHours(sleep))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }

            Spacer()

            // Data quality indicator
            if metrics.dataQuality.hasGaps {
                Image(systemName: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            isSelected ? Theme.Colors.neonTeal.opacity(0.1) :
            (metrics.date.isToday ? Color.blue.opacity(0.05) : Color.clear)
        )
        .overlay(
            isSelected ?
            RoundedRectangle(cornerRadius: 0)
                .stroke(Theme.Colors.neonTeal.opacity(0.3), lineWidth: 1)
            : nil
        )
    }

    private func scoreIndicator(value: Int?, icon: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            if let score = value {
                Text("\(score)")
                    .font(.caption)
                    .fontWeight(.medium)
            } else {
                Text("--")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: metrics.date)
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: metrics.date)
    }

    private var recoveryColor: Color {
        guard let score = metrics.recoveryScore?.score else { return .gray }
        switch score {
        case 0...33: return .red
        case 34...66: return .yellow
        default: return .green
        }
    }

    private var strainColor: Color {
        guard let score = metrics.strainScore?.score else { return .gray }
        switch score {
        case 0...33: return .blue
        case 34...66: return .orange
        default: return .red
        }
    }

    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h\(m)m"
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
                Theme.Colors.sovereignBlack.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Date header
                        VStack(spacing: 4) {
                            Text(metrics.date.formattedDate)
                                .font(Theme.Fonts.header(size: 20))
                                .foregroundColor(.white)

                            Text(metrics.date.relativeDescription)
                                .font(Theme.Fonts.tensor(size: 14))
                                .foregroundColor(Theme.Colors.textGray)
                        }
                        .padding(.top)

                        // Main scores with gauges
                        HStack(spacing: 20) {
                            if let recovery = metrics.recoveryScore {
                                VStack(spacing: 8) {
                                    SovereignGauge(
                                        score: recovery.score,
                                        type: .recovery,
                                        size: 100
                                    )
                                    Text(recovery.category.rawValue)
                                        .font(Theme.Fonts.label(size: 12))
                                        .foregroundColor(Theme.Colors.textGray)
                                }
                            }

                            if let strain = metrics.strainScore {
                                VStack(spacing: 8) {
                                    SovereignGauge(
                                        score: strain.score,
                                        type: .strain,
                                        size: 100
                                    )
                                    Text(strain.category.rawValue)
                                        .font(Theme.Fonts.label(size: 12))
                                        .foregroundColor(Theme.Colors.textGray)
                                }
                            }
                        }

                        // Heart metrics row
                        HStack(spacing: 16) {
                            if let hrv = metrics.hrv?.nightlySDNN ?? metrics.hrv?.averageSDNN {
                                metricBox(label: "HRV", value: "\(Int(hrv))", unit: "ms", color: Theme.Colors.neonTeal)
                            }

                            if let rhr = metrics.heartRate?.restingBPM {
                                metricBox(label: "RHR", value: "\(Int(rhr))", unit: "bpm", color: Theme.Colors.neonRed)
                            }
                        }

                        // Sleep section
                        if let sleep = metrics.sleep {
                            sleepSection(sleep)
                        }

                        // HR Zones section
                        if let zones = metrics.zoneDistribution, zones.totalMinutes > 0 {
                            hrZonesSection(zones)
                        }

                        // Workouts section
                        if let workouts = metrics.workouts, workouts.totalWorkouts > 0 {
                            workoutsSection(workouts)
                        }

                        // Activity section
                        if let activity = metrics.activity {
                            activitySection(activity)
                        }

                        // Data quality
                        dataQualitySection(metrics.dataQuality)
                    }
                    .padding()
                }
            }
            .navigationTitle("Day Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.sovereignBlack, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.Colors.neonTeal)
                }
            }
        }
    }

    // MARK: - Sleep Section

    private func sleepSection(_ sleep: DailySleepSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("SLEEP")

            HStack(spacing: 16) {
                metricBox(label: "Duration", value: formatHours(sleep.totalSleepHours), unit: "", color: Theme.Colors.neonGreen)
                metricBox(label: "Efficiency", value: "\(Int(sleep.averageEfficiency))", unit: "%", color: Theme.Colors.neonGreen)
                if sleep.totalInterruptions > 0 {
                    metricBox(label: "Interruptions", value: "\(sleep.totalInterruptions)", unit: "", color: Theme.Colors.neonGold)
                }
            }

            // Sleep stages
            VStack(spacing: 8) {
                stageRow("Deep", minutes: sleep.combinedStageBreakdown.deepMinutes, color: .indigo, ideal: "13-23%", actual: sleep.combinedStageBreakdown.deepPercentage)
                stageRow("Core", minutes: sleep.combinedStageBreakdown.coreMinutes, color: .blue, ideal: "50-60%", actual: sleep.combinedStageBreakdown.corePercentage)
                stageRow("REM", minutes: sleep.combinedStageBreakdown.remMinutes, color: .cyan, ideal: "20-25%", actual: sleep.combinedStageBreakdown.remPercentage)
                if sleep.combinedStageBreakdown.awakeMinutes > 0 {
                    stageRow("Awake", minutes: sleep.combinedStageBreakdown.awakeMinutes, color: .orange, ideal: nil, actual: nil)
                }
            }
            .padding()
            .background(Theme.Colors.panelGray)
            .cornerRadius(12)
        }
    }

    private func stageRow(_ name: String, minutes: Int, color: Color, ideal: String?, actual: Double?) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(name)
                .font(Theme.Fonts.tensor(size: 14))
                .foregroundColor(.white)

            Spacer()

            Text(formatMinutes(minutes))
                .font(Theme.Fonts.tensor(size: 14))
                .foregroundColor(.white)

            if let percentage = actual {
                Text("(\(Int(percentage))%)")
                    .font(Theme.Fonts.label(size: 12))
                    .foregroundColor(Theme.Colors.textGray)
                    .frame(width: 45, alignment: .trailing)
            }
        }
    }

    // MARK: - HR Zones Section

    private func hrZonesSection(_ zones: ZoneTimeDistribution) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("HEART RATE ZONES")

            VStack(spacing: 8) {
                zoneRow("Zone 1 (Recovery)", minutes: zones.zone1Minutes, color: .gray, weight: "0.1x")
                zoneRow("Zone 2 (Fat Burn)", minutes: zones.zone2Minutes, color: .blue, weight: "0.3x")
                zoneRow("Zone 3 (Aerobic)", minutes: zones.zone3Minutes, color: .green, weight: "0.6x")
                zoneRow("Zone 4 (Anaerobic)", minutes: zones.zone4Minutes, color: .orange, weight: "1.0x")
                zoneRow("Zone 5 (Max)", minutes: zones.zone5Minutes, color: .red, weight: "1.5x")

                Divider().background(Theme.Colors.textGray.opacity(0.3))

                HStack {
                    Text("Total")
                        .font(Theme.Fonts.tensor(size: 14))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(zones.totalMinutes) min")
                        .font(Theme.Fonts.tensor(size: 14))
                        .foregroundColor(Theme.Colors.neonTeal)
                }
            }
            .padding()
            .background(Theme.Colors.panelGray)
            .cornerRadius(12)
        }
    }

    private func zoneRow(_ name: String, minutes: Int, color: Color, weight: String) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(name)
                .font(Theme.Fonts.tensor(size: 12))
                .foregroundColor(.white)

            Text(weight)
                .font(Theme.Fonts.label(size: 10))
                .foregroundColor(Theme.Colors.textGray)

            Spacer()

            Text("\(minutes) min")
                .font(Theme.Fonts.tensor(size: 12))
                .foregroundColor(.white)
        }
    }

    // MARK: - Workouts Section

    private func workoutsSection(_ workouts: DailyWorkoutSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("WORKOUTS (\(workouts.totalWorkouts))")

            ForEach(workouts.workouts) { workout in
                HStack {
                    Image(systemName: workout.activityType.icon)
                        .foregroundColor(Theme.Colors.neonRed)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.activityType.rawValue.capitalized)
                            .font(Theme.Fonts.tensor(size: 14))
                            .foregroundColor(.white)

                        Text(workout.formattedDuration)
                            .font(Theme.Fonts.label(size: 12))
                            .foregroundColor(Theme.Colors.textGray)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        if let energy = workout.totalEnergyBurned {
                            Text("\(Int(energy)) kcal")
                                .font(Theme.Fonts.tensor(size: 12))
                                .foregroundColor(.white)
                        }

                        if let avgHR = workout.averageHeartRate {
                            Text("Avg HR: \(Int(avgHR))")
                                .font(Theme.Fonts.label(size: 10))
                                .foregroundColor(Theme.Colors.textGray)
                        }
                    }
                }
                .padding()
                .background(Theme.Colors.panelGray)
                .cornerRadius(8)
            }

            // Totals
            HStack(spacing: 16) {
                metricBox(label: "Duration", value: "\(workouts.totalDurationMinutes)", unit: "min", color: Theme.Colors.neonRed)
                metricBox(label: "Energy", value: "\(Int(workouts.totalEnergyBurned))", unit: "kcal", color: Theme.Colors.neonRed)
            }
        }
    }

    // MARK: - Activity Section

    private func activitySection(_ activity: DailyActivitySummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("ACTIVITY")

            HStack(spacing: 16) {
                metricBox(label: "Steps", value: "\(activity.steps)", unit: "", color: Theme.Colors.neonGold)
                metricBox(label: "Active", value: "\(Int(activity.activeEnergy))", unit: "kcal", color: Theme.Colors.neonGold)
                metricBox(label: "Distance", value: String(format: "%.1f", activity.distance), unit: "km", color: Theme.Colors.neonGold)
            }
        }
    }

    // MARK: - Data Quality Section

    private func dataQualitySection(_ quality: DataQualityIndicator) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("DATA QUALITY")

            HStack(spacing: 16) {
                qualityIndicator("Heart Rate", completeness: quality.heartRateCompleteness)
                qualityIndicator("HRV", completeness: quality.hrvCompleteness)
                qualityIndicator("Sleep", completeness: quality.sleepCompleteness)
                qualityIndicator("Activity", completeness: quality.activityCompleteness)
            }
            .padding()
            .background(Theme.Colors.panelGray)
            .cornerRadius(12)
        }
    }

    private func qualityIndicator(_ name: String, completeness: Double) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(qualityColor(completeness))
                .frame(width: 12, height: 12)

            Text(name)
                .font(Theme.Fonts.label(size: 10))
                .foregroundColor(Theme.Colors.textGray)
        }
        .frame(maxWidth: .infinity)
    }

    private func qualityColor(_ completeness: Double) -> Color {
        switch completeness {
        case 0.75...: return Theme.Colors.neonGreen
        case 0.5..<0.75: return Theme.Colors.neonGold
        default: return Theme.Colors.neonRed
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Theme.Fonts.label(size: 12))
            .foregroundColor(Theme.Colors.textGray)
            .tracking(1)
    }

    private func metricBox(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(Theme.Fonts.label(size: 10))
                .foregroundColor(Theme.Colors.textGray)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(Theme.Fonts.tensor(size: 18))
                    .foregroundColor(.white)

                if !unit.isEmpty {
                    Text(unit)
                        .font(Theme.Fonts.label(size: 10))
                        .foregroundColor(Theme.Colors.textGray)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.Colors.panelGray)
        .cornerRadius(8)
        .overlay(
            Rectangle()
                .fill(color)
                .frame(height: 2),
            alignment: .top
        )
    }

    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 {
            return "\(h)h \(m)m"
        }
        return "\(m)m"
    }
}

struct ScoreCard: View {
    let title: String
    let score: Int
    let category: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(score)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(category)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    TimelineView()
        .environmentObject(HealthKitManager())
}
