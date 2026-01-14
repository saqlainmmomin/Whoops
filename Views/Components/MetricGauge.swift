import SwiftUI

struct MetricGauge: View {
    let value: Double
    let maxValue: Double
    let color: Color
    let size: CGFloat

    var progress: Double {
        min(value / maxValue, 1.0)
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    Color(.systemGray5),
                    lineWidth: Constants.UI.gaugeLineWidth
                )

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: Constants.UI.gaugeLineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            // Center text
            VStack(spacing: 0) {
                Text("\(Int(value))")
                    .font(.system(size: size * 0.28, weight: .bold, design: .rounded))

                Text("/ \(Int(maxValue))")
                    .font(.system(size: size * 0.12))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Linear Gauge Variant

struct LinearMetricGauge: View {
    let value: Double
    let maxValue: Double
    let color: Color
    let height: CGFloat

    var progress: Double {
        min(value / maxValue, 1.0)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color(.systemGray5))

                // Progress
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: geometry.size.width * progress)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Mini Gauge for Compact Views

struct MiniGauge: View {
    let value: Double
    let maxValue: Double
    let color: Color

    var progress: Double {
        min(value / maxValue, 1.0)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 4)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 32, height: 32)
    }
}

// MARK: - Score Ring

struct ScoreRing: View {
    let score: Int
    let category: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            MetricGauge(
                value: Double(score),
                maxValue: 100,
                color: color,
                size: 80
            )

            Text(category)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        HStack(spacing: 32) {
            MetricGauge(value: 72, maxValue: 100, color: .green, size: 100)
            MetricGauge(value: 45, maxValue: 100, color: .orange, size: 100)
            MetricGauge(value: 15, maxValue: 100, color: .red, size: 100)
        }

        VStack(spacing: 16) {
            LinearMetricGauge(value: 72, maxValue: 100, color: .green, height: 8)
            LinearMetricGauge(value: 45, maxValue: 100, color: .orange, height: 8)
            LinearMetricGauge(value: 15, maxValue: 100, color: .red, height: 8)
        }
        .padding(.horizontal)

        HStack(spacing: 16) {
            MiniGauge(value: 72, maxValue: 100, color: .green)
            MiniGauge(value: 45, maxValue: 100, color: .orange)
            MiniGauge(value: 15, maxValue: 100, color: .red)
        }
    }
    .padding()
}
