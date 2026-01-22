import SwiftUI
import Charts

struct TimeSeriesPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct BaselineBandChart: View {
    let data: [TimeSeriesPoint]
    let baseline: Double
    let stdDev: Double
    let label: String
    var accentColor: Color = Theme.Colors.hrvPositive

    private var upperBound: Double { baseline + stdDev }
    private var lowerBound: Double { baseline - stdDev }

    var body: some View {
        Chart {
            // Baseline band (1 std dev range)
            RectangleMark(
                xStart: .value("Start", data.first?.date ?? Date()),
                xEnd: .value("End", data.last?.date ?? Date()),
                yStart: .value("Lower", lowerBound),
                yEnd: .value("Upper", upperBound)
            )
            .foregroundStyle(accentColor.opacity(0.15))

            // Baseline center line
            RuleMark(y: .value("Baseline", baseline))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(Theme.Colors.textTertiary)

            // Data line
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value(label, point.value)
                )
                .foregroundStyle(accentColor)
                .interpolationMethod(.catmullRom)
            }

            // Data points
            ForEach(data) { point in
                PointMark(
                    x: .value("Date", point.date),
                    y: .value(label, point.value)
                )
                .foregroundStyle(
                    point.value >= lowerBound && point.value <= upperBound
                        ? accentColor
                        : Theme.Colors.hrvNegative
                )
                .symbolSize(point.date == data.last?.date ? 60 : 30)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow))
                    .font(Theme.Fonts.mono(9))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(Theme.Fonts.mono(9))
                    .foregroundStyle(Theme.Colors.textTertiary)
                AxisGridLine()
                    .foregroundStyle(Theme.Colors.borderSubtle)
            }
        }
        .chartPlotStyle { plotArea in
            plotArea.background(Theme.Colors.surfaceCard.opacity(0.5))
        }
    }
}

struct BaselineBandChartCard: View {
    let title: String
    let data: [TimeSeriesPoint]
    let baseline: Double
    let stdDev: Double
    let currentValue: Double
    var accentColor: Color = Theme.Colors.hrvPositive

    private var isInRange: Bool {
        currentValue >= (baseline - stdDev) && currentValue <= (baseline + stdDev)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(title.uppercased())
                    .font(Theme.Fonts.label(11))
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .tracking(1)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(isInRange ? Theme.Colors.hrvPositive : Theme.Colors.hrvNegative)
                        .frame(width: 6, height: 6)

                    Text(isInRange ? "In Range" : "Outside Range")
                        .font(Theme.Fonts.label(10))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }

            BaselineBandChart(
                data: data,
                baseline: baseline,
                stdDev: stdDev,
                label: title,
                accentColor: accentColor
            )
            .frame(height: 120)

            // Stats row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CURRENT")
                        .font(Theme.Fonts.label(8))
                        .foregroundStyle(Theme.Colors.textTertiary)
                    Text(String(format: "%.0f", currentValue))
                        .font(Theme.Fonts.mono(14))
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                Spacer()

                VStack(alignment: .center, spacing: 2) {
                    Text("BASELINE")
                        .font(Theme.Fonts.label(8))
                        .foregroundStyle(Theme.Colors.textTertiary)
                    Text(String(format: "%.0f", baseline))
                        .font(Theme.Fonts.mono(14))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("RANGE")
                        .font(Theme.Fonts.label(8))
                        .foregroundStyle(Theme.Colors.textTertiary)
                    Text("\(Int(baseline - stdDev))-\(Int(baseline + stdDev))")
                        .font(Theme.Fonts.mono(14))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Theme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

#Preview {
    let sampleData: [TimeSeriesPoint] = (0..<7).map { day in
        TimeSeriesPoint(
            date: Calendar.current.date(byAdding: .day, value: -6 + day, to: Date())!,
            value: Double.random(in: 40...60)
        )
    }

    return VStack(spacing: 20) {
        BaselineBandChartCard(
            title: "HRV",
            data: sampleData,
            baseline: 50,
            stdDev: 8,
            currentValue: 52,
            accentColor: Theme.Colors.hrvPositive
        )

        BaselineBandChartCard(
            title: "Resting HR",
            data: sampleData.map { TimeSeriesPoint(date: $0.date, value: 55 + Double.random(in: -5...5)) },
            baseline: 58,
            stdDev: 4,
            currentValue: 62,
            accentColor: Theme.Colors.rhrPositive
        )
    }
    .preferredColorScheme(.dark)
    .padding()
    .background(Theme.Colors.void)
}
