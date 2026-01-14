import SwiftUI

struct BaselineComparisonView: View {
    let current: Double
    let baseline: Double
    let unit: String
    let label: String
    let higherIsBetter: Bool

    private var difference: Double {
        current - baseline
    }

    private var percentChange: Double {
        guard baseline != 0 else { return 0 }
        return (difference / baseline) * 100
    }

    private var isPositive: Bool {
        higherIsBetter ? difference > 0 : difference < 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline) {
                // Current value
                Text(formatValue(current))
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // Comparison
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: difference >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption2)

                        Text(formatValue(abs(difference)))
                            .font(.caption)
                    }
                    .foregroundColor(isPositive ? .green : .orange)

                    Text("vs \(formatValue(baseline)) baseline")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Visual comparison bar
            comparisonBar
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var comparisonBar: some View {
        GeometryReader { geometry in
            let center = geometry.size.width / 2
            let maxOffset = center * 0.8
            let clampedPercent = max(min(percentChange, 50), -50) / 50
            let offset = clampedPercent * maxOffset

            ZStack {
                // Background
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 4)
                    .cornerRadius(2)

                // Center line
                Rectangle()
                    .fill(Color(.systemGray3))
                    .frame(width: 2, height: 8)
                    .position(x: center, y: 4)

                // Change bar
                if abs(offset) > 1 {
                    Rectangle()
                        .fill(isPositive ? Color.green : Color.orange)
                        .frame(width: abs(offset), height: 4)
                        .position(
                            x: offset > 0 ? center + offset/2 : center + offset/2,
                            y: 4
                        )
                        .cornerRadius(2)
                }
            }
        }
        .frame(height: 8)
    }

    private func formatValue(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.0f", value)
        } else if value >= 10 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

// MARK: - Compact Baseline Comparison

struct CompactBaselineComparison: View {
    let current: Double
    let baseline: Double?
    let unit: String
    let higherIsBetter: Bool

    private var difference: Double? {
        guard let base = baseline else { return nil }
        return current - base
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(formatValue(current))
                .fontWeight(.medium)

            Text(unit)
                .foregroundColor(.secondary)

            if let diff = difference {
                let isPositive = higherIsBetter ? diff > 0 : diff < 0
                HStack(spacing: 2) {
                    Image(systemName: diff >= 0 ? "arrow.up" : "arrow.down")
                    Text(formatValue(abs(diff)))
                }
                .font(.caption)
                .foregroundColor(isPositive ? .green : .orange)
            }
        }
        .font(.subheadline)
    }

    private func formatValue(_ value: Double) -> String {
        if value >= 100 {
            return String(format: "%.0f", value)
        } else if value >= 10 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

// MARK: - Z-Score Display

struct ZScoreDisplay: View {
    let zScore: Double
    let label: String

    private var interpretation: String {
        switch zScore {
        case ..<(-1.5): return "Significantly below"
        case -1.5..<(-0.5): return "Below baseline"
        case -0.5...0.5: return "Normal"
        case 0.5..<1.5: return "Above baseline"
        default: return "Significantly above"
        }
    }

    private var isPositive: Bool {
        zScore > 0.5
    }

    private var isNegative: Bool {
        zScore < -0.5
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(String(format: "%+.2f σ", zScore))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(scoreColor)
            }

            Text(interpretation)
                .font(.caption2)
                .foregroundColor(.secondary)

            // Z-score visual
            zScoreBar
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var scoreColor: Color {
        if isPositive { return .green }
        if isNegative { return .orange }
        return .secondary
    }

    private var zScoreBar: some View {
        GeometryReader { geometry in
            let center = geometry.size.width / 2
            let maxOffset = center * 0.8
            let clampedZ = max(min(zScore, 2), -2) / 2
            let offset = clampedZ * maxOffset

            ZStack {
                // Background with zones
                HStack(spacing: 0) {
                    Rectangle().fill(Color.red.opacity(0.2))
                    Rectangle().fill(Color.orange.opacity(0.2))
                    Rectangle().fill(Color.green.opacity(0.2))
                    Rectangle().fill(Color.green.opacity(0.2))
                    Rectangle().fill(Color.blue.opacity(0.2))
                }
                .frame(height: 8)
                .cornerRadius(4)

                // Current position marker
                Circle()
                    .fill(scoreColor)
                    .frame(width: 12, height: 12)
                    .position(x: center + offset, y: 4)
            }
        }
        .frame(height: 12)
    }
}

#Preview {
    VStack(spacing: 16) {
        BaselineComparisonView(
            current: 72,
            baseline: 65,
            unit: "ms",
            label: "HRV (SDNN)",
            higherIsBetter: true
        )

        BaselineComparisonView(
            current: 58,
            baseline: 62,
            unit: "bpm",
            label: "Resting Heart Rate",
            higherIsBetter: false
        )

        HStack {
            CompactBaselineComparison(current: 72, baseline: 65, unit: "ms", higherIsBetter: true)
            Spacer()
            CompactBaselineComparison(current: 58, baseline: 62, unit: "bpm", higherIsBetter: false)
        }

        ZScoreDisplay(zScore: 1.2, label: "HRV Deviation")
        ZScoreDisplay(zScore: -0.8, label: "RHR Deviation")
        ZScoreDisplay(zScore: 0.1, label: "Sleep Duration")
    }
    .padding()
}
