import SwiftUI

/// Pixel-Perfect Whoop Strain Tab
/// Features strain gauge (0-21), message card, activities, statistics, and charts
struct StrainTab: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showStrainInfo = false

    // Computed properties
    private var strainScore: Double {
        viewModel.strainScoreNormalized
    }

    private var strainTarget: Double {
        viewModel.optimalStrainTarget ?? 14.0
    }

    private var activeCalories: Int {
        Int(viewModel.todayMetrics?.activity?.activeEnergy ?? 0)
    }

    private var avgHeartRate: Int {
        Int(viewModel.todayMetrics?.heartRate?.averageBPM ?? 0)
    }

    private var strainMessage: (title: String, message: String) {
        StrainMessage.generate(current: strainScore, target: strainTarget)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.moduleP) {

                // HERO: Strain Gauge
                strainGauge
                    .padding(.top, Theme.Spacing.moduleP)

                // Message Card
                MessageCard(
                    title: strainMessage.title,
                    message: strainMessage.message,
                    accentColor: Theme.Colors.whoopCyan
                )
                .padding(.horizontal, Theme.Spacing.moduleP)

                // Strain Activities
                strainActivitiesSection
                    .padding(.horizontal, Theme.Spacing.moduleP)

                // Statistics Section (VS. PREVIOUS 30 DAYS)
                statisticsSection
                    .padding(.horizontal, Theme.Spacing.moduleP)

                // What is Strain?
                WhatIsInfoCard(
                    title: "What is Strain?",
                    description: "Discover the science behind Strain and how it measures performance.",
                    onTap: { showStrainInfo = true }
                )
                .padding(.horizontal, Theme.Spacing.moduleP)

                // 7-Day Charts Section
                chartsSection
                    .padding(.horizontal, Theme.Spacing.moduleP)
            }
            .padding(.bottom, Theme.Spacing.moduleP)
        }
        .background(Theme.Colors.primary)
        .sheet(isPresented: $showStrainInfo) {
            strainInfoSheet
        }
    }

    // MARK: - Strain Gauge (Whoop-style - label INSIDE, 135° start)
    // Gap ST-1: Increase size to heroGaugeDiameter (200pt), fix gradient
    // Gap ST-2: Move "STRAIN" label inside gauge

    private var strainGauge: some View {
        VStack(spacing: 16) {
            // Gauge with STRAIN label + value inside
            ZStack {
                // Background track (270° arc from 135°)
                Circle()
                    .trim(from: 0, to: 0.75) // 270° arc
                    .stroke(
                        Theme.Colors.tertiary,
                        style: StrokeStyle(lineWidth: Theme.Dimensions.gaugeStrokeWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))

                // Progress arc with cyan → dark cyan gradient
                // Per DESIGN_SPEC §8.2: starts at 135°, sweeps 270° × progress
                Circle()
                    .trim(from: 0, to: (strainScore / 21.0) * 0.75)
                    .stroke(
                        AngularGradient(
                            colors: [Theme.Colors.whoopCyan, Theme.Colors.whoopCyanDark],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(270 * strainScore / 21.0)
                        ),
                        style: StrokeStyle(
                            lineWidth: Theme.Dimensions.gaugeStrokeWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(135))

                // Center content: STRAIN label + value
                VStack(spacing: 4) {
                    Text("STRAIN")
                        .font(Theme.Fonts.sectionHeader)
                        .tracking(2)
                        .foregroundColor(Theme.Colors.textSecondary)

                    // Large strain value
                    Text(String(format: "%.1f", strainScore))
                        .font(.system(size: 72, weight: .black, design: .rounded))
                        .foregroundColor(Theme.Colors.whoopCyan)
                }

                // Info button (top-right)
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { showStrainInfo = true }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 20))
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
                    Spacer()
                }
                .padding(8)
            }
            .frame(width: Theme.Dimensions.heroGaugeDiameter, height: Theme.Dimensions.heroGaugeDiameter)

            // Share button (below gauge)
            Button(action: { /* TODO: Share strain */ }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                    Text("SHARE")
                        .font(Theme.Fonts.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(Theme.Colors.whoopCyan)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.Colors.cardBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Theme.Colors.whoopCyan.opacity(0.5), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Strain Activities Section

    @ViewBuilder
    private var strainActivitiesSection: some View {
        if let workouts = viewModel.todayWorkouts, !workouts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("STRAIN ACTIVITIES")
                    .whoopSectionHeader()

                ForEach(workouts) { workout in
                    let workoutStrain = calculateWorkoutStrain(workout)
                    StrainActivityRow(
                        strainValue: workoutStrain,
                        activityType: workout.type.capitalized,
                        timeRange: formatTimeRange(workout.startTime, duration: workout.duration),
                        calories: Int(workout.activeCalories),
                        duration: formatDuration(workout.duration / 3600)
                    )
                }
            }
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        StatisticsSection(
            title: "STRAIN STATISTICS",
            stats: [
                StatRow(
                    icon: "heart.fill",
                    label: "Average HR",
                    value: "\(avgHeartRate) bpm",
                    trend: nil,
                    baseline: viewModel.sevenDayBaseline?.averageRestingHR.map { "\(Int($0 * 1.5)) bpm" }
                ),
                StatRow(
                    icon: "flame.fill",
                    label: "Calories",
                    value: formatCalories(Double(activeCalories)),
                    trend: nil,
                    baseline: viewModel.sevenDayBaseline?.averageActiveEnergy.map { formatCalories($0) }
                )
            ],
            rightLabel: "VS. PREVIOUS 30 DAYS"
        )
    }

    // MARK: - Charts Section
    // Gap ST-5: Chart cards with icon + UPPERCASE title + chevron header

    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.moduleP) {
            // Section Header
            Text("VS. LAST 7 DAYS")
                .whoopSectionHeader()

            // Strain Bar Chart
            VStack(alignment: .leading, spacing: 8) {
                ChartCardHeader(icon: "bolt.fill", title: "STRAIN")
                StrainBarChart(data: strainChartData)
            }
            .padding(Theme.Dimensions.cardPadding)
            .whoopCard()

            // Average HR Line Chart
            VStack(alignment: .leading, spacing: 8) {
                ChartCardHeader(icon: "heart.fill", title: "AVERAGE HEART RATE")
                SimpleLineChart(
                    data: avgHRChartData,
                    color: Color(hex: "#FF6B6B")
                )
            }
            .padding(Theme.Dimensions.cardPadding)
            .whoopCard()

            // Calories Bar Chart
            VStack(alignment: .leading, spacing: 8) {
                ChartCardHeader(icon: "flame.fill", title: "CALORIES")
                VerticalBarChart(
                    data: caloriesChartData,
                    barColor: Theme.Colors.whoopTeal
                )
            }
            .padding(Theme.Dimensions.cardPadding)
            .whoopCard()
        }
    }

    // MARK: - Chart Data
    // Gap S-11: Two-line day labels

    private var weekDayLabels: [(label: String, secondary: String, isToday: Bool)] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEE"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d"
            return (label: dayFormatter.string(from: date), secondary: dateFormatter.string(from: date), isToday: daysAgo == 0)
        }
    }

    private var strainChartData: [BarChartData] {
        let labels = weekDayLabels
        return viewModel.weeklyMetrics.suffix(7).enumerated().map { index, metric in
            let dayInfo = labels[index % labels.count]
            let strainValue = Double(metric.strainScore?.score ?? 0) / 100.0 * 21.0
            return .strain(label: dayInfo.label, secondaryLabel: dayInfo.secondary, value: strainValue, isToday: dayInfo.isToday)
        }
    }

    private var avgHRChartData: [ChartDataPoint] {
        let labels = weekDayLabels
        return viewModel.weeklyMetrics.suffix(7).enumerated().map { index, metric in
            let dayInfo = labels[index % labels.count]
            return ChartDataPoint(label: dayInfo.label, value: metric.heartRate?.averageBPM ?? 0)
        }
    }

    private var caloriesChartData: [BarChartData] {
        let labels = weekDayLabels
        return viewModel.weeklyMetrics.suffix(7).enumerated().map { index, metric in
            let dayInfo = labels[index % labels.count]
            let calories = metric.activity?.activeEnergy ?? 0
            return .calories(label: dayInfo.label, secondaryLabel: dayInfo.secondary, value: calories, isToday: dayInfo.isToday)
        }
    }

    // MARK: - Strain Info Sheet

    private var strainInfoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("What is Strain?")
                        .font(Theme.Fonts.mediumValue)
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text("Strain quantifies the cardiovascular load experienced by your body. It's measured on a 0-21 scale and is based on your heart rate during activities and throughout the day.")
                        .font(Theme.Fonts.body)
                        .foregroundColor(Theme.Colors.textSecondary)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Strain is calculated from:")
                            .font(Theme.Fonts.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.Colors.textPrimary)

                        BulletPoint(text: "Time spent in different heart rate zones")
                        BulletPoint(text: "Workout duration and intensity")
                        BulletPoint(text: "All-day cardiovascular activity")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Strain Zones:")
                            .font(Theme.Fonts.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.Colors.textPrimary)

                        StrainZoneRow(range: "0-9", label: "Light", description: "Recovery day activities")
                        StrainZoneRow(range: "10-13", label: "Moderate", description: "Maintaining fitness")
                        StrainZoneRow(range: "14-17", label: "Strenuous", description: "Building fitness")
                        StrainZoneRow(range: "18-21", label: "All Out", description: "Peak performance day")
                    }
                }
                .padding()
            }
            .background(Theme.Colors.primary)
            .navigationTitle("Strain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showStrainInfo = false }
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatTimeRange(_ start: Date, duration: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let end = start.addingTimeInterval(duration)
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
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

    private func calculateWorkoutStrain(_ workout: WorkoutEntry) -> Double {
        // Simple strain calculation based on duration and heart rate
        let durationHours = workout.duration / 3600
        let intensityFactor = min((workout.averageHeartRate ?? 0) / 180.0, 1.5)
        return min(durationHours * intensityFactor * 10, 21)
    }
}

// MARK: - Strain Zone Row

struct StrainZoneRow: View {
    let range: String
    let label: String
    let description: String

    private var zoneColor: Color {
        switch label.lowercased() {
        case "light": return Theme.Colors.whoopTeal
        case "moderate": return Theme.Colors.whoopCyan
        case "strenuous": return Theme.Colors.whoopYellow
        case "all out": return Color(hex: "#FF3B30")
        default: return Theme.Colors.textSecondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(zoneColor)
                .frame(width: 4, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(range)
                        .font(Theme.Fonts.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text(label)
                        .font(Theme.Fonts.caption)
                        .foregroundColor(zoneColor)
                }

                Text(description)
                    .font(Theme.Fonts.footnote)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
    }
}

#Preview {
    StrainTab(viewModel: DashboardViewModel(healthKitManager: HealthKitManager()))
        .preferredColorScheme(.dark)
}
