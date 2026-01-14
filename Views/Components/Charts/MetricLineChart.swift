import SwiftUI
import Charts

struct MetricLineChart: View {
    let dataPoints: [MetricChartDataPoint]
    let color: Color
    let unit: String
    let baselineValue: Double?
    var showBaseline: Bool = true

    @State private var selectedRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case week = "7D"
        case month = "28D"
        case quarter = "90D"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 28
            case .quarter: return 90
            }
        }
    }

    private var filteredData: [MetricChartDataPoint] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedRange.days, to: Date()) ?? Date()
        return dataPoints.filter { $0.date >= cutoffDate }.sorted { $0.date < $1.date }
    }

    private var minValue: Double {
        let values = filteredData.map { $0.value }
        let minData = values.min() ?? 0
        let minWithBaseline = baselineValue.map { min(minData, $0) } ?? minData
        return minWithBaseline * 0.85
    }

    private var maxValue: Double {
        let values = filteredData.map { $0.value }
        let maxData = values.max() ?? 100
        let maxWithBaseline = baselineValue.map { max(maxData, $0) } ?? maxData
        return maxWithBaseline * 1.15
    }

    var body: some View {
        VStack(spacing: 16) {
            // Time range picker
            Picker("Time Range", selection: $selectedRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)

            if filteredData.count >= 2 {
                Chart {
                    // Baseline band (if available)
                    if showBaseline, let baseline = baselineValue {
                        RuleMark(y: .value("Baseline", baseline))
                            .foregroundStyle(Theme.Colors.textGray.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            .annotation(position: .trailing, alignment: .leading) {
                                Text("avg")
                                    .font(.caption2)
                                    .foregroundColor(Theme.Colors.textGray)
                            }
                    }

                    // Data line
                    ForEach(filteredData) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(color)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }

                    // Current day marker
                    if let lastPoint = filteredData.last {
                        PointMark(
                            x: .value("Date", lastPoint.date),
                            y: .value("Value", lastPoint.value)
                        )
                        .foregroundStyle(color)
                        .symbolSize(80)
                        .annotation(position: .top) {
                            Text(String(format: "%.0f", lastPoint.value))
                                .font(Theme.Fonts.tensor(size: 12))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(color.opacity(0.8))
                                .cornerRadius(4)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: xAxisStride)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date.formatted(.dateTime.day().month(.abbreviated)))
                                    .font(.caption2)
                                    .foregroundColor(Theme.Colors.textGray)
                            }
                        }
                        AxisGridLine()
                            .foregroundStyle(Theme.Colors.panelGray)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))")
                                    .font(.caption2)
                                    .foregroundColor(Theme.Colors.textGray)
                            }
                        }
                        AxisGridLine()
                            .foregroundStyle(Theme.Colors.panelGray.opacity(0.5))
                    }
                }
                .chartYScale(domain: minValue...maxValue)
                .frame(height: 200)
            } else {
                // Not enough data
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.Colors.textGray)

                    Text("Not enough data")
                        .font(Theme.Fonts.tensor(size: 14))
                        .foregroundColor(Theme.Colors.textGray)

                    Text("Keep tracking to see trends")
                        .font(Theme.Fonts.label(size: 12))
                        .foregroundColor(Theme.Colors.textGray.opacity(0.7))
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.panelGray)
                .cornerRadius(12)
            }

            // Summary stats
            if filteredData.count >= 2 {
                HStack(spacing: 20) {
                    chartStat(label: "Avg", value: averageValue)
                    chartStat(label: "Min", value: filteredData.map { $0.value }.min() ?? 0)
                    chartStat(label: "Max", value: filteredData.map { $0.value }.max() ?? 0)
                }
            }
        }
        .padding()
        .background(Theme.Colors.panelGray)
        .cornerRadius(12)
    }

    private var xAxisStride: Int {
        switch selectedRange {
        case .week: return 1
        case .month: return 7
        case .quarter: return 14
        }
    }

    private var averageValue: Double {
        guard !filteredData.isEmpty else { return 0 }
        return filteredData.map { $0.value }.reduce(0, +) / Double(filteredData.count)
    }

    private func chartStat(label: String, value: Double) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(Theme.Fonts.label(size: 10))
                .foregroundColor(Theme.Colors.textGray)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(String(format: "%.0f", value))
                    .font(Theme.Fonts.tensor(size: 16))
                    .foregroundColor(.white)

                Text(unit)
                    .font(Theme.Fonts.label(size: 10))
                    .foregroundColor(Theme.Colors.textGray)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct MetricChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        MetricLineChart(
            dataPoints: (0..<14).map { i in
                MetricChartDataPoint(
                    date: Calendar.current.date(byAdding: .day, value: -13 + i, to: Date())!,
                    value: Double.random(in: 35...55)
                )
            },
            color: Theme.Colors.neonTeal,
            unit: "ms",
            baselineValue: 45
        )
        .padding()
    }
}
