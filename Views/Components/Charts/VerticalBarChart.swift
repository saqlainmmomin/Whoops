import SwiftUI

/// Whoop-style 7-day vertical bar chart with tap selection
/// Used for Recovery, Sleep Performance, Strain, Calories, etc.
struct VerticalBarChart: View {
    let data: [BarChartData]
    var barColor: Color = Theme.Colors.whoopYellow
    var showLabels: Bool = true
    var showValues: Bool = true
    var onSelect: ((Int) -> Void)?

    @State private var selectedIndex: Int?

    private let barWidth: CGFloat = Theme.Dimensions.barChartBarWidth
    private let barGap: CGFloat = Theme.Dimensions.barChartGap

    private var maxValue: Double {
        max(data.map { $0.value }.max() ?? 1, 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Selection indicator
            if let index = selectedIndex, index < data.count {
                HStack {
                    Text(data[index].label)
                        .font(Theme.Fonts.footnote)
                        .foregroundColor(Theme.Colors.textSecondary)
                    Text(data[index].formattedValue)
                        .font(Theme.Fonts.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(barColor)
                }
                .transition(.opacity)
            }

            // Chart area
            GeometryReader { geo in
                HStack(alignment: .bottom, spacing: barGap) {
                    ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                        ZStack(alignment: .bottom) {
                            // "today" column background highlight
                            if item.isToday {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.Colors.tertiary.opacity(0.4))
                            }

                            VStack(spacing: 4) {
                                // Value label — always visible above each bar
                                if showValues {
                                    Text(item.formattedValue)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(
                                            selectedIndex == index ? barColor :
                                            (item.isToday ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                                        )
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }

                                // Bar
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(barColorForIndex(index, value: item.value))
                                    .frame(height: max(4, geo.size.height * 0.65 * (item.value / maxValue)))
                            }
                        }
                        .frame(maxWidth: .infinity)
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
            .frame(height: Theme.Dimensions.barChartHeight)

            // Day labels
            if showLabels {
                HStack(spacing: barGap) {
                    ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 1) {
                            Text(item.label)
                                .font(.system(size: 10, weight: item.isToday ? .bold : .regular))
                                .foregroundColor(selectedIndex == index ? barColor : (item.isToday ? Theme.Colors.textPrimary : Theme.Colors.textTertiary))
                            if let secondary = item.secondaryLabel {
                                Text(secondary)
                                    .font(.system(size: 10, weight: item.isToday ? .bold : .regular))
                                    .foregroundColor(selectedIndex == index ? barColor : (item.isToday ? Theme.Colors.textPrimary : Theme.Colors.textTertiary))
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            // Summary row — avg value for context
            if data.count > 1 {
                let values = data.map { $0.value }.filter { $0 > 0 }
                if !values.isEmpty {
                    HStack(spacing: 16) {
                        chartSummaryItem(label: "AVG", value: values.reduce(0, +) / Double(values.count))
                        chartSummaryItem(label: "HIGH", value: values.max() ?? 0)
                        chartSummaryItem(label: "LOW", value: values.min() ?? 0)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private func chartSummaryItem(label: String, value: Double) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Theme.Colors.textTertiary)
                .tracking(0.5)
            Text(String(format: value >= 100 ? "%.0f" : "%.1f", value))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func barColorForIndex(_ index: Int, value: Double) -> Color {
        let normalizedValue = value / maxValue
        let baseOpacity = 0.5 + normalizedValue * 0.5

        if let selected = selectedIndex {
            return index == selected ? barColor : barColor.opacity(0.3)
        }
        return barColor.opacity(baseOpacity)
    }
}

/// Model for bar chart data point
/// Gap S-11: Supports two-line labels (day name + date) and today highlight
struct BarChartData: Identifiable {
    let id = UUID()
    let label: String
    let secondaryLabel: String? // Date number for two-line format
    let value: Double
    let formattedValue: String
    let isToday: Bool

    init(label: String, secondaryLabel: String? = nil, value: Double, formattedValue: String? = nil, isToday: Bool = false) {
        self.label = label
        self.secondaryLabel = secondaryLabel
        self.value = value
        self.formattedValue = formattedValue ?? "\(Int(value))"
        self.isToday = isToday
    }

    /// Create from percentage (0-100)
    static func percentage(label: String, secondaryLabel: String? = nil, value: Double, isToday: Bool = false) -> BarChartData {
        BarChartData(label: label, secondaryLabel: secondaryLabel, value: value, formattedValue: "\(Int(value))%", isToday: isToday)
    }

    /// Create from strain value (0-21)
    static func strain(label: String, secondaryLabel: String? = nil, value: Double, isToday: Bool = false) -> BarChartData {
        BarChartData(label: label, secondaryLabel: secondaryLabel, value: value, formattedValue: String(format: "%.1f", value), isToday: isToday)
    }

    /// Create from calories
    static func calories(label: String, secondaryLabel: String? = nil, value: Double, isToday: Bool = false) -> BarChartData {
        let formatted = value >= 1000 ? String(format: "%.1fk", value / 1000) : "\(Int(value))"
        return BarChartData(label: label, secondaryLabel: secondaryLabel, value: value, formattedValue: formatted, isToday: isToday)
    }
}

/// Recovery-specific bar chart with color coding and tap selection
struct RecoveryBarChart: View {
    let data: [BarChartData]
    var onSelect: ((Int) -> Void)?

    @State private var selectedIndex: Int?

    var body: some View {
        VStack(spacing: 8) {
            // Selection indicator
            if let index = selectedIndex, index < data.count {
                HStack {
                    Text(data[index].label)
                        .font(Theme.Fonts.footnote)
                        .foregroundColor(Theme.Colors.textSecondary)
                    Text(data[index].formattedValue)
                        .font(Theme.Fonts.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(recoveryColor(for: data[index].value))
                }
                .transition(.opacity)
            }

            GeometryReader { geo in
                HStack(alignment: .bottom, spacing: Theme.Dimensions.barChartGap) {
                    ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                        ZStack(alignment: .bottom) {
                            // "today" column highlight
                            if item.isToday {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.Colors.tertiary.opacity(0.4))
                            }

                            VStack(spacing: 4) {
                                // Value label — always visible, color-coded
                                Text(item.formattedValue)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(
                                        selectedIndex == index ? recoveryColor(for: item.value) :
                                        (item.value > 0 ? recoveryColor(for: item.value).opacity(0.8) : Theme.Colors.textTertiary)
                                    )
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(barColorForIndex(index, score: item.value))
                                    .frame(height: max(4, geo.size.height * 0.65 * (item.value / 100)))
                            }
                        }
                        .frame(maxWidth: .infinity)
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
            .frame(height: Theme.Dimensions.barChartHeight)

            // Two-line day labels
            HStack(spacing: Theme.Dimensions.barChartGap) {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                    VStack(spacing: 1) {
                        Text(item.label)
                            .font(.system(size: 10, weight: item.isToday ? .bold : .regular))
                            .foregroundColor(selectedIndex == index ? recoveryColor(for: item.value) : (item.isToday ? Theme.Colors.textPrimary : Theme.Colors.textTertiary))
                        if let secondary = item.secondaryLabel {
                            Text(secondary)
                                .font(.system(size: 10, weight: item.isToday ? .bold : .regular))
                                .foregroundColor(selectedIndex == index ? recoveryColor(for: item.value) : (item.isToday ? Theme.Colors.textPrimary : Theme.Colors.textTertiary))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Summary row
            let values = data.map { $0.value }.filter { $0 > 0 }
            if !values.isEmpty {
                HStack(spacing: 16) {
                    recoverySummaryItem(label: "AVG", value: values.reduce(0, +) / Double(values.count))
                    recoverySummaryItem(label: "HIGH", value: values.max() ?? 0)
                    recoverySummaryItem(label: "LOW", value: values.min() ?? 0)
                }
                .padding(.top, 4)
            }
        }
    }

    private func recoverySummaryItem(label: String, value: Double) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Theme.Colors.textTertiary)
                .tracking(0.5)
            Text("\(Int(value))%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(recoveryColor(for: value))
        }
        .frame(maxWidth: .infinity)
    }

    private func recoveryColor(for score: Double) -> Color {
        switch score {
        case 67...100:
            return Theme.Colors.whoopTeal
        case 34..<67:
            return Theme.Colors.whoopYellow
        default:
            return Color(hex: "#FF3B30")
        }
    }

    private func barColorForIndex(_ index: Int, score: Double) -> Color {
        let color = recoveryColor(for: score)
        if let selected = selectedIndex {
            return index == selected ? color : color.opacity(0.3)
        }
        return color
    }
}

/// Strain-specific bar chart (0-21 scale)
struct StrainBarChart: View {
    let data: [BarChartData]

    var body: some View {
        VerticalBarChart(
            data: data,
            barColor: Theme.Colors.whoopCyan,
            showLabels: true,
            showValues: true
        )
    }
}

#Preview {
    VStack(spacing: 32) {
        VStack(alignment: .leading, spacing: 8) {
            Text("RECOVERY")
                .whoopSectionHeader()

            RecoveryBarChart(data: [
                .percentage(label: "M", value: 85),
                .percentage(label: "T", value: 72),
                .percentage(label: "W", value: 91),
                .percentage(label: "T", value: 45),
                .percentage(label: "F", value: 76),
                .percentage(label: "S", value: 82),
                .percentage(label: "S", value: 89)
            ])
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("STRAIN")
                .whoopSectionHeader()

            StrainBarChart(data: [
                .strain(label: "M", value: 12.5),
                .strain(label: "T", value: 8.2),
                .strain(label: "W", value: 15.1),
                .strain(label: "T", value: 10.0),
                .strain(label: "F", value: 14.3),
                .strain(label: "S", value: 18.2),
                .strain(label: "S", value: 6.5)
            ])
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("CALORIES")
                .whoopSectionHeader()

            VerticalBarChart(
                data: [
                    .calories(label: "M", value: 2100),
                    .calories(label: "T", value: 1850),
                    .calories(label: "W", value: 2400),
                    .calories(label: "T", value: 1950),
                    .calories(label: "F", value: 2200),
                    .calories(label: "S", value: 2800),
                    .calories(label: "S", value: 1600)
                ],
                barColor: Theme.Colors.whoopTeal
            )
        }
    }
    .padding()
    .background(Theme.Colors.primary)
}
