import SwiftUI

/// Pixel-Perfect Whoop Recovery Tab
/// Features recovery gauge, message card, statistics, and charts
struct RecoveryTab: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showRecoveryInfo = false

    // Computed properties
    private var recoveryScore: Int {
        viewModel.todayMetrics?.recoveryScore?.score ?? 0
    }

    private var hrvValue: Double {
        viewModel.todayMetrics?.hrv?.nightlySDNN ?? viewModel.todayMetrics?.hrv?.averageSDNN ?? 0
    }

    private var rhrValue: Double {
        viewModel.todayMetrics?.heartRate?.restingBPM ?? 0
    }

    private var recoveryMessage: (title: String, message: String) {
        RecoveryMessage.generate(score: recoveryScore)
    }

    private var accentColor: Color {
        switch recoveryScore {
        case 67...100: return Theme.Colors.whoopTeal
        case 34..<67: return Theme.Colors.whoopYellow
        default: return Color(hex: "#FF3B30")
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.moduleP) {

                // HERO: Recovery Gauge
                recoveryGauge
                    .padding(.top, Theme.Spacing.moduleP)

                // Message Card
                MessageCard(
                    title: recoveryMessage.title,
                    message: recoveryMessage.message,
                    accentColor: accentColor
                )
                .padding(.horizontal, Theme.Spacing.moduleP)

                // Statistics Section (VS. PREVIOUS 30 DAYS)
                statisticsSection
                    .padding(.horizontal, Theme.Spacing.moduleP)

                // What is Recovery?
                WhatIsInfoCard(
                    title: "What is Recovery?",
                    description: "Discover the science behind Recovery and how it measures health and fitness.",
                    onTap: { showRecoveryInfo = true }
                )
                .padding(.horizontal, Theme.Spacing.moduleP)

                // 7-Day Charts Section
                chartsSection
                    .padding(.horizontal, Theme.Spacing.moduleP)
            }
            .padding(.bottom, Theme.Spacing.moduleP)
        }
        .background(Theme.Colors.primary)
        .sheet(isPresented: $showRecoveryInfo) {
            recoveryInfoSheet
        }
    }

    // MARK: - Recovery Gauge (Whoop-style - label INSIDE, 135° start)
    // Gap R-1: Increase size to heroGaugeDiameter (200pt), fix gradient
    // Gap R-2: Move "RECOVERY" label inside gauge
    // Gap R-7: Change start angle from -90° to 135° per DESIGN_SPEC §8.1

    private var recoveryGauge: some View {
        VStack(spacing: 16) {
            // Gauge with RECOVERY label + percentage inside
            ZStack {
                // Background track (270° arc from 135°)
                Circle()
                    .trim(from: 0, to: 0.75) // 270° arc
                    .stroke(
                        Theme.Colors.tertiary,
                        style: StrokeStyle(lineWidth: Theme.Dimensions.gaugeStrokeWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))

                // Progress arc with yellow → orange gradient
                // Per DESIGN_SPEC §8.1: starts at 135°, sweeps 270° × progress
                Circle()
                    .trim(from: 0, to: Double(recoveryScore) / 100.0 * 0.75)
                    .stroke(
                        AngularGradient(
                            colors: [Theme.Colors.whoopYellow, Theme.Colors.whoopOrange],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(270 * Double(recoveryScore) / 100.0)
                        ),
                        style: StrokeStyle(
                            lineWidth: Theme.Dimensions.gaugeStrokeWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(135))

                // Center content: RECOVERY label + percentage + info button
                VStack(spacing: 4) {
                    Text("RECOVERY")
                        .font(Theme.Fonts.sectionHeader)
                        .tracking(2)
                        .foregroundColor(Theme.Colors.textSecondary)

                    // Large percentage value
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("\(recoveryScore)")
                            .font(.system(size: 72, weight: .black, design: .rounded))
                            .foregroundColor(Theme.Colors.textPrimary)
                        Text("%")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                }

                // Info button (top-right)
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { showRecoveryInfo = true }) {
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
            Button(action: { /* TODO: Share recovery */ }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                    Text("SHARE")
                        .font(Theme.Fonts.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(Theme.Colors.whoopYellow)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.Colors.cardBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Theme.Colors.whoopYellow.opacity(0.5), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        StatisticsSection(
            title: "RECOVERY STATISTICS",
            stats: [
                StatRow(
                    icon: "waveform.path.ecg",
                    label: "HRV",
                    value: "\(Int(hrvValue))ms",
                    trend: viewModel.hrvTrend,
                    baseline: viewModel.sevenDayBaseline?.averageHRV.map { "\(Int($0))ms" }
                ),
                StatRow(
                    icon: "heart.fill",
                    label: "RHR",
                    value: "\(Int(rhrValue)) bpm",
                    trend: invertedTrend(viewModel.rhrTrend),
                    baseline: viewModel.sevenDayBaseline?.averageRestingHR.map { "\(Int($0)) bpm" }
                ),
                StatRow(
                    icon: "lungs.fill",
                    label: "Respiratory Rate",
                    value: "N/A",
                    trend: nil,
                    baseline: nil
                ),
                StatRow(
                    icon: "moon.fill",
                    label: "Sleep Performance",
                    value: "\(Int(viewModel.todayMetrics?.sleep?.averageEfficiency ?? 0))%",
                    trend: viewModel.sleepTrend,
                    baseline: nil
                )
            ],
            rightLabel: "VS. PREVIOUS 30 DAYS"
        )
    }

    // MARK: - Charts Section
    // Gap R-8: Chart cards with icon + UPPERCASE title + chevron header

    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.moduleP) {
            // Section Header
            Text("VS. LAST 7 DAYS")
                .whoopSectionHeader()

            // Recovery Bar Chart
            VStack(alignment: .leading, spacing: 8) {
                ChartCardHeader(icon: "bell.fill", title: "RECOVERY")
                RecoveryBarChart(data: recoveryChartData)
            }
            .padding(Theme.Dimensions.cardPadding)
            .whoopCard()

            // HRV Line Chart
            VStack(alignment: .leading, spacing: 8) {
                ChartCardHeader(icon: "waveform.path.ecg", title: "HEART RATE VARIABILITY")
                SimpleLineChart(
                    data: hrvChartData,
                    color: Theme.Colors.whoopTeal
                )
            }
            .padding(Theme.Dimensions.cardPadding)
            .whoopCard()

            // RHR Line Chart
            VStack(alignment: .leading, spacing: 8) {
                ChartCardHeader(icon: "heart.fill", title: "RESTING HEART RATE")
                SimpleLineChart(
                    data: rhrChartData,
                    color: Color(hex: "#FF6B6B")
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

    private var recoveryChartData: [BarChartData] {
        let labels = weekDayLabels
        return viewModel.weeklyMetrics.suffix(7).enumerated().map { index, metric in
            let dayInfo = labels[index % labels.count]
            let score = Double(metric.recoveryScore?.score ?? 0)
            return .percentage(label: dayInfo.label, secondaryLabel: dayInfo.secondary, value: score, isToday: dayInfo.isToday)
        }
    }

    private var hrvChartData: [ChartDataPoint] {
        let labels = weekDayLabels
        return viewModel.weeklyMetrics.suffix(7).enumerated().map { index, metric in
            let dayInfo = labels[index % labels.count]
            let value = metric.hrv?.nightlySDNN ?? metric.hrv?.averageSDNN ?? 0
            return ChartDataPoint(label: dayInfo.label, value: value)
        }
    }

    private var rhrChartData: [ChartDataPoint] {
        let labels = weekDayLabels
        return viewModel.weeklyMetrics.suffix(7).enumerated().map { index, metric in
            let dayInfo = labels[index % labels.count]
            return ChartDataPoint(label: dayInfo.label, value: metric.heartRate?.restingBPM ?? 0)
        }
    }

    // MARK: - Recovery Info Sheet

    private var recoveryInfoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("What is Recovery?")
                        .font(Theme.Fonts.mediumValue)
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text("Recovery measures how prepared your body is to take on strain. It's calculated using your heart rate variability (HRV), resting heart rate, and sleep performance.")
                        .font(Theme.Fonts.body)
                        .foregroundColor(Theme.Colors.textSecondary)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recovery is influenced by:")
                            .font(Theme.Fonts.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.Colors.textPrimary)

                        BulletPoint(text: "Heart Rate Variability (HRV)")
                        BulletPoint(text: "Resting Heart Rate")
                        BulletPoint(text: "Sleep duration and quality")
                        BulletPoint(text: "Previous day's strain")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recovery Zones:")
                            .font(Theme.Fonts.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.Colors.textPrimary)

                        RecoveryZoneRow(range: "67-100%", label: "Green", description: "Peak recovery - ready for high strain")
                        RecoveryZoneRow(range: "34-66%", label: "Yellow", description: "Moderate recovery - balance activity and rest")
                        RecoveryZoneRow(range: "0-33%", label: "Red", description: "Low recovery - prioritize rest")
                    }
                }
                .padding()
            }
            .background(Theme.Colors.primary)
            .navigationTitle("Recovery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showRecoveryInfo = false }
                }
            }
        }
    }

    // MARK: - Helpers

    private func invertedTrend(_ trend: TrendDirection?) -> TrendDirection? {
        guard let trend = trend else { return nil }
        switch trend {
        case .improving: return .declining  // Lower RHR shows as up arrow in UI
        case .declining: return .improving
        case .stable: return .stable
        }
    }
}

// MARK: - Simple Line Chart with Tap Selection

struct SimpleLineChart: View {
    let data: [ChartDataPoint]
    var color: Color = Theme.Colors.whoopTeal
    var onSelect: ((Int) -> Void)?

    @State private var selectedIndex: Int?

    private var maxValue: Double {
        max(data.map { $0.value }.max() ?? 1, 1)
    }

    private var minValue: Double {
        data.map { $0.value }.filter { $0 > 0 }.min() ?? 0
    }

    private var valueRange: Double {
        max(maxValue - minValue, 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Selection indicator
            if let index = selectedIndex, index < data.count {
                HStack {
                    Text(data[index].label)
                        .font(Theme.Fonts.footnote)
                        .foregroundColor(Theme.Colors.textSecondary)
                    Text(formatValue(data[index].value))
                        .font(Theme.Fonts.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                }
                .transition(.opacity)
            }

            // Y-axis range indicator (max → min)
            HStack {
                VStack(alignment: .leading) {
                    Text(formatValue(maxValue))
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(Theme.Colors.textTertiary)
                    Spacer()
                    Text(formatValue(minValue > 0 ? minValue : 0))
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
                .frame(width: 28)

                GeometryReader { geo in
                    ZStack {
                        // Grid lines
                        VStack(spacing: 0) {
                            ForEach(0..<4) { _ in
                                Spacer()
                                Rectangle()
                                    .fill(Theme.Colors.borderSubtle)
                                    .frame(height: 1)
                            }
                            Spacer()
                        }

                        // Line
                        LineShape(
                            data: data.map { $0.value },
                            minValue: minValue,
                            maxValue: maxValue
                        )
                        .stroke(color.opacity(selectedIndex != nil ? 0.5 : 1.0), lineWidth: Theme.Dimensions.lineStrokeWidth)

                        // Data points + value labels
                        ForEach(Array(data.enumerated()), id: \.element.id) { index, point in
                            if point.value > 0 {
                                let x = geo.size.width * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                                let y = geo.size.height * (1 - CGFloat((point.value - minValue) / valueRange))

                                // Value label above each point
                                if selectedIndex == nil || selectedIndex == index {
                                    Text(formatValue(point.value))
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(selectedIndex == index ? color : Theme.Colors.textSecondary)
                                        .position(x: x, y: max(y - 14, 8))
                                }

                                Circle()
                                    .fill(pointColorForIndex(index))
                                    .frame(width: selectedIndex == index ? Theme.Dimensions.dataPointDiameter * 1.5 : Theme.Dimensions.dataPointDiameter,
                                           height: selectedIndex == index ? Theme.Dimensions.dataPointDiameter * 1.5 : Theme.Dimensions.dataPointDiameter)
                                    .position(x: x, y: y)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            if selectedIndex == index {
                                                selectedIndex = nil
                                            } else {
                                                selectedIndex = index
                                                onSelect?(index)
                                            }
                                        }
                                    }
                            }
                        }

                        // Invisible tap targets for easier selection
                        ForEach(Array(data.enumerated()), id: \.element.id) { index, point in
                            if point.value > 0 {
                                let x = geo.size.width * CGFloat(index) / CGFloat(max(data.count - 1, 1))

                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 30, height: geo.size.height)
                                    .position(x: x, y: geo.size.height / 2)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            if selectedIndex == index {
                                                selectedIndex = nil
                                            } else {
                                                selectedIndex = index
                                                onSelect?(index)
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .frame(height: Theme.Dimensions.lineChartHeight)

            // X-axis labels
            HStack {
                Spacer().frame(width: 28) // Match Y-axis label width
                ForEach(Array(data.enumerated()), id: \.element.id) { index, point in
                    Text(point.label)
                        .font(Theme.Fonts.footnote)
                        .foregroundColor(selectedIndex == index ? color : Theme.Colors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func pointColorForIndex(_ index: Int) -> Color {
        if let selected = selectedIndex {
            return index == selected ? color : color.opacity(0.3)
        }
        return color
    }

    private func formatValue(_ value: Double) -> String {
        if value >= 100 {
            return "\(Int(value))"
        } else if value >= 10 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - Recovery Zone Row

struct RecoveryZoneRow: View {
    let range: String
    let label: String
    let description: String

    private var zoneColor: Color {
        switch label.lowercased() {
        case "green": return Theme.Colors.whoopTeal
        case "yellow": return Theme.Colors.whoopYellow
        case "red": return Color(hex: "#FF3B30")
        default: return Theme.Colors.textSecondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(zoneColor)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(range)
                    .font(Theme.Fonts.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(description)
                    .font(Theme.Fonts.footnote)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
    }
}

#Preview {
    RecoveryTab(viewModel: DashboardViewModel(healthKitManager: HealthKitManager()))
        .preferredColorScheme(.dark)
}
