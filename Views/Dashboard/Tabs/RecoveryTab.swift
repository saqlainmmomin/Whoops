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

    // MARK: - Recovery Gauge (Whoop-style - label above)

    private var recoveryGauge: some View {
        VStack(spacing: 16) {
            // RECOVERY label ABOVE gauge with info button
            HStack {
                Spacer()

                Text("RECOVERY")
                    .font(Theme.Fonts.sectionHeader)
                    .tracking(2)
                    .foregroundColor(Theme.Colors.textSecondary)

                Spacer()

                Button(action: { showRecoveryInfo = true }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
            .padding(.horizontal, 40)

            // Gauge with percentage inside
            ZStack {
                // Background track
                Circle()
                    .stroke(Theme.Colors.tertiary, lineWidth: Theme.Dimensions.gaugeStrokeWidth)

                // Progress arc with yellow gradient
                Circle()
                    .trim(from: 0, to: Double(recoveryScore) / 100.0)
                    .stroke(
                        AngularGradient(
                            colors: [Theme.Colors.whoopYellow, Theme.Colors.whoopOrange],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(-90 + 360 * Double(recoveryScore) / 100)
                        ),
                        style: StrokeStyle(
                            lineWidth: Theme.Dimensions.gaugeStrokeWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))

                // Center content - just the percentage with striking font
                VStack(spacing: -4) {
                    Text("\(recoveryScore)")
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundColor(Theme.Colors.textPrimary)
                    + Text("%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.textPrimary)
                }
            }
            .frame(width: Theme.Dimensions.standardGaugeDiameter, height: Theme.Dimensions.standardGaugeDiameter)

            // Share button
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
                    label: "Resting Heart Rate",
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

    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.moduleP) {
            // Section Header
            Text("VS. LAST 7 DAYS")
                .whoopSectionHeader()

            // Recovery Bar Chart
            VStack(alignment: .leading, spacing: 8) {
                Text("Recovery")
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.Colors.textPrimary)

                RecoveryBarChart(data: recoveryChartData)
            }
            .padding(Theme.Dimensions.cardPadding)
            .whoopCard()

            // HRV Line Chart
            VStack(alignment: .leading, spacing: 8) {
                Text("Heart Rate Variability")
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.Colors.textPrimary)

                SimpleLineChart(
                    data: hrvChartData,
                    color: Theme.Colors.whoopTeal
                )
            }
            .padding(Theme.Dimensions.cardPadding)
            .whoopCard()

            // RHR Line Chart
            VStack(alignment: .leading, spacing: 8) {
                Text("Resting Heart Rate")
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.Colors.textPrimary)

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

    private var recoveryChartData: [BarChartData] {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return viewModel.weeklyMetrics.suffix(7).enumerated().map { index, metric in
            let dayLabel = days[index % 7]
            let score = Double(metric.recoveryScore?.score ?? 0)
            return .percentage(label: dayLabel, value: score)
        }
    }

    private var hrvChartData: [ChartDataPoint] {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return viewModel.weeklyMetrics.suffix(7).enumerated().map { index, metric in
            let dayLabel = days[index % 7]
            let value = metric.hrv?.nightlySDNN ?? metric.hrv?.averageSDNN ?? 0
            return ChartDataPoint(label: dayLabel, value: value)
        }
    }

    private var rhrChartData: [ChartDataPoint] {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return viewModel.weeklyMetrics.suffix(7).enumerated().map { index, metric in
            let dayLabel = days[index % 7]
            return ChartDataPoint(label: dayLabel, value: metric.heartRate?.restingBPM ?? 0)
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

                    // Data points
                    ForEach(Array(data.enumerated()), id: \.element.id) { index, point in
                        if point.value > 0 {
                            let x = geo.size.width * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                            let y = geo.size.height * (1 - CGFloat((point.value - minValue) / valueRange))

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
                            let y = geo.size.height * (1 - CGFloat((point.value - minValue) / valueRange))

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
            .frame(height: Theme.Dimensions.lineChartHeight)

            // X-axis labels
            HStack {
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
