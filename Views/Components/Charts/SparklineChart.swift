import SwiftUI
import Charts

struct SparklineChart: View {
    let dataPoints: [Double]
    let color: Color
    var height: CGFloat = 30

    private var chartData: [ChartDataPoint] {
        dataPoints.enumerated().map { index, value in
            ChartDataPoint(index: index, value: value)
        }
    }

    private var minValue: Double {
        (dataPoints.min() ?? 0) * 0.9
    }

    private var maxValue: Double {
        (dataPoints.max() ?? 100) * 1.1
    }

    var body: some View {
        if dataPoints.count >= 2 {
            Chart(chartData) { point in
                LineMark(
                    x: .value("Day", point.index),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                AreaMark(
                    x: .value("Day", point.index),
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
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: minValue...maxValue)
            .frame(height: height)
        } else {
            // Not enough data
            Rectangle()
                .fill(Theme.Colors.panelGray)
                .frame(height: height)
                .overlay(
                    Text("--")
                        .font(Theme.Fonts.tensor(size: 12))
                        .foregroundColor(Theme.Colors.textGray)
                )
        }
    }
}

private struct ChartDataPoint: Identifiable {
    let id = UUID()
    let index: Int
    let value: Double
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            SparklineChart(
                dataPoints: [42, 45, 38, 52, 48, 55, 50],
                color: Theme.Colors.neonTeal
            )

            SparklineChart(
                dataPoints: [65, 58, 62, 70, 68, 72, 65],
                color: Theme.Colors.neonRed
            )

            SparklineChart(
                dataPoints: [7.2, 6.8, 7.5, 8.0, 7.3, 6.5, 7.8],
                color: Theme.Colors.neonGreen
            )
        }
        .padding()
    }
}
