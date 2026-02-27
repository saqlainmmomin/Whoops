import SwiftUI

/// Whoop-style dual line chart with tap selection for comparing two metrics
/// Used for Hours vs Sleep Need comparison
struct DualLineChart: View {
    let primaryData: [ChartDataPoint]
    let secondaryData: [ChartDataPoint]
    let primaryLabel: String
    let secondaryLabel: String
    var primaryColor: Color = Theme.Colors.whoopTeal
    var secondaryColor: Color = Theme.Colors.textSecondary
    var onSelect: ((Int) -> Void)?

    @State private var selectedIndex: Int?

    private var allValues: [Double] {
        primaryData.map { $0.value } + secondaryData.map { $0.value }
    }

    private var maxValue: Double {
        max(allValues.max() ?? 1, 1)
    }

    private var minValue: Double {
        max(allValues.min() ?? 0, 0)
    }

    private var valueRange: Double {
        max(maxValue - minValue, 1)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Legend with selection info
            HStack(spacing: 16) {
                if let index = selectedIndex, index < primaryData.count {
                    // Show selected values
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Circle().fill(primaryColor).frame(width: 8, height: 8)
                            Text("\(primaryLabel): \(formatHours(primaryData[index].value))")
                                .font(Theme.Fonts.footnote)
                                .foregroundColor(primaryColor)
                        }
                        if index < secondaryData.count {
                            HStack(spacing: 8) {
                                Circle().fill(secondaryColor).frame(width: 8, height: 8)
                                Text("\(secondaryLabel): \(formatHours(secondaryData[index].value))")
                                    .font(Theme.Fonts.footnote)
                                    .foregroundColor(secondaryColor)
                            }
                        }
                    }
                } else {
                    LegendItem(color: primaryColor, label: primaryLabel)
                    LegendItem(color: secondaryColor, label: secondaryLabel)
                }
                Spacer()
            }

            // Chart
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

                    // Selection indicator line
                    if let index = selectedIndex, index < primaryData.count {
                        let x = geo.size.width * CGFloat(index) / CGFloat(max(primaryData.count - 1, 1))
                        Rectangle()
                            .fill(Theme.Colors.textSecondary.opacity(0.3))
                            .frame(width: 1)
                            .position(x: x, y: geo.size.height / 2)
                    }

                    // Secondary line (background)
                    LineShape(
                        data: secondaryData.map { $0.value },
                        minValue: minValue,
                        maxValue: maxValue
                    )
                    .stroke(
                        secondaryColor.opacity(selectedIndex != nil ? 0.3 : 0.5),
                        style: StrokeStyle(lineWidth: Theme.Dimensions.lineStrokeWidth, dash: [4, 4])
                    )

                    // Primary line (foreground)
                    LineShape(
                        data: primaryData.map { $0.value },
                        minValue: minValue,
                        maxValue: maxValue
                    )
                    .stroke(primaryColor.opacity(selectedIndex != nil ? 0.5 : 1.0), lineWidth: Theme.Dimensions.lineStrokeWidth)

                    // Data points for primary line
                    ForEach(Array(primaryData.enumerated()), id: \.element.id) { index, point in
                        let x = geo.size.width * CGFloat(index) / CGFloat(max(primaryData.count - 1, 1))
                        let y = geo.size.height * (1 - (point.value - minValue) / valueRange)

                        Circle()
                            .fill(pointColorForIndex(index))
                            .frame(width: selectedIndex == index ? Theme.Dimensions.dataPointDiameter * 1.5 : Theme.Dimensions.dataPointDiameter,
                                   height: selectedIndex == index ? Theme.Dimensions.dataPointDiameter * 1.5 : Theme.Dimensions.dataPointDiameter)
                            .position(x: x, y: y)
                    }

                    // Invisible tap targets
                    ForEach(Array(primaryData.enumerated()), id: \.element.id) { index, _ in
                        let x = geo.size.width * CGFloat(index) / CGFloat(max(primaryData.count - 1, 1))

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
            .frame(height: Theme.Dimensions.lineChartHeight)

            // X-axis labels
            HStack {
                ForEach(Array(primaryData.enumerated()), id: \.element.id) { index, point in
                    Text(point.label)
                        .font(Theme.Fonts.footnote)
                        .foregroundColor(selectedIndex == index ? primaryColor : Theme.Colors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func pointColorForIndex(_ index: Int) -> Color {
        if let selected = selectedIndex {
            return index == selected ? primaryColor : primaryColor.opacity(0.3)
        }
        return primaryColor
    }

    private func formatHours(_ value: Double) -> String {
        let hours = Int(value)
        let minutes = Int((value - Double(hours)) * 60)
        return "\(hours):\(String(format: "%02d", minutes))"
    }
}

/// Legend item for chart
struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(Theme.Fonts.footnote)
                .foregroundColor(Theme.Colors.textSecondary)
        }
    }
}

/// Shape for drawing line chart
struct LineShape: Shape {
    let data: [Double]
    let minValue: Double
    let maxValue: Double

    private var range: Double {
        max(maxValue - minValue, 1)
    }

    func path(in rect: CGRect) -> Path {
        guard data.count > 1 else { return Path() }

        var path = Path()

        for (index, value) in data.enumerated() {
            let x = rect.width * CGFloat(index) / CGFloat(data.count - 1)
            let y = rect.height * (1 - CGFloat((value - minValue) / range))

            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

/// Model for chart data point
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

#Preview {
    VStack(spacing: 24) {
        DualLineChart(
            primaryData: [
                ChartDataPoint(label: "M", value: 6.5),
                ChartDataPoint(label: "T", value: 7.2),
                ChartDataPoint(label: "W", value: 5.8),
                ChartDataPoint(label: "T", value: 7.5),
                ChartDataPoint(label: "F", value: 6.0),
                ChartDataPoint(label: "S", value: 8.5),
                ChartDataPoint(label: "S", value: 7.8)
            ],
            secondaryData: [
                ChartDataPoint(label: "M", value: 7.5),
                ChartDataPoint(label: "T", value: 7.5),
                ChartDataPoint(label: "W", value: 7.5),
                ChartDataPoint(label: "T", value: 7.5),
                ChartDataPoint(label: "F", value: 7.5),
                ChartDataPoint(label: "S", value: 7.5),
                ChartDataPoint(label: "S", value: 7.5)
            ],
            primaryLabel: "Hours Slept",
            secondaryLabel: "Sleep Need"
        )
    }
    .padding()
    .background(Theme.Colors.primary)
}
