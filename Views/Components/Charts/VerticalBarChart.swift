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
                        VStack(spacing: 4) {
                            // Value label
                            if showValues && selectedIndex == nil {
                                Text(item.formattedValue)
                                    .font(Theme.Fonts.footnote)
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }

                            // Bar
                            RoundedRectangle(cornerRadius: 4)
                                .fill(barColorForIndex(index, value: item.value))
                                .frame(height: max(4, geo.size.height * 0.7 * (item.value / maxValue)))
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
                        Text(item.label)
                            .font(Theme.Fonts.footnote)
                            .foregroundColor(selectedIndex == index ? barColor : Theme.Colors.textTertiary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
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
struct BarChartData: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let formattedValue: String

    init(label: String, value: Double, formattedValue: String? = nil) {
        self.label = label
        self.value = value
        self.formattedValue = formattedValue ?? "\(Int(value))"
    }

    /// Create from percentage (0-100)
    static func percentage(label: String, value: Double) -> BarChartData {
        BarChartData(label: label, value: value, formattedValue: "\(Int(value))%")
    }

    /// Create from strain value (0-21)
    static func strain(label: String, value: Double) -> BarChartData {
        BarChartData(label: label, value: value, formattedValue: String(format: "%.1f", value))
    }

    /// Create from calories
    static func calories(label: String, value: Double) -> BarChartData {
        let formatted = value >= 1000 ? String(format: "%.1fk", value / 1000) : "\(Int(value))"
        return BarChartData(label: label, value: value, formattedValue: formatted)
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
                        VStack(spacing: 4) {
                            if selectedIndex == nil {
                                Text(item.formattedValue)
                                    .font(Theme.Fonts.footnote)
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }

                            RoundedRectangle(cornerRadius: 4)
                                .fill(barColorForIndex(index, score: item.value))
                                .frame(height: max(4, geo.size.height * 0.7 * (item.value / 100)))
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

            HStack(spacing: Theme.Dimensions.barChartGap) {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                    Text(item.label)
                        .font(Theme.Fonts.footnote)
                        .foregroundColor(selectedIndex == index ? recoveryColor(for: item.value) : Theme.Colors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
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
