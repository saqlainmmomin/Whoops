import SwiftUI

/// Single-metric circular gauge with NO nested rings
/// Clean, Whoop-aligned design
struct CircularProgressGauge: View {
    let value: Double           // 0-100
    let color: Color
    let label: String
    let sublabel: String?

    init(
        value: Double,
        color: Color,
        label: String,
        sublabel: String? = nil
    ) {
        self.value = value
        self.color = color
        self.label = label
        self.sublabel = sublabel
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Theme.Colors.tertiary, lineWidth: 12)

            // Progress arc
            Circle()
                .trim(from: 0, to: min(value / 100, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: 4) {
                Text("\(Int(value))%")
                    .font(Theme.Fonts.heroMetric)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .minimumScaleFactor(0.5)

                Text(label.uppercased())
                    .font(Theme.Fonts.label(13))
                    .tracking(1)
                    .foregroundColor(Theme.Colors.textSecondary)

                if let sublabel {
                    Text(sublabel)
                        .font(Theme.Fonts.label(11))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }
        }
        // NO GLOW EFFECTS
        .accessibilityLabel("\(label): \(Int(value)) percent\(sublabel.map { ", \($0)" } ?? "")")
        .accessibilityHint("Double tap for \(label.lowercased()) details")
    }
}

// MARK: - Strain Gauge (0-21 Scale)

/// Strain-specific gauge with target ring indicator
struct StrainGauge: View {
    let current: Double         // 0-21 scale
    let target: Double          // 0-21 scale

    var body: some View {
        let progress = min(current / 21, 1.0)
        let targetProgress = min(target / 21, 1.0)

        ZStack {
            // Background track
            Circle()
                .stroke(Theme.Colors.tertiary, lineWidth: 12)

            // Target indicator (subtle dashed ring)
            Circle()
                .trim(from: 0, to: targetProgress)
                .stroke(
                    Theme.Colors.textTertiary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4])
                )
                .rotationEffect(.degrees(-90))

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Theme.Colors.strain(current: current, target: target),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: 4) {
                Text(String(format: "%.1f", current))
                    .font(Theme.Fonts.display(48))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text("STRAIN")
                    .font(Theme.Fonts.label(13))
                    .tracking(1)
                    .foregroundColor(Theme.Colors.textSecondary)

                Text("Target: \(String(format: "%.1f", target))")
                    .font(Theme.Fonts.label(10))
                    .foregroundColor(Theme.Colors.textTertiary)
            }
        }
        .accessibilityLabel("Strain: \(String(format: "%.1f", current)) out of 21, target \(String(format: "%.1f", target))")
    }
}

// MARK: - Recovery Component Bar

/// Horizontal progress bar for recovery breakdown
struct RecoveryComponentBar: View {
    let label: String
    let value: Double
    let suffix: String
    let progress: Double       // 0-1
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(Theme.Fonts.label(13))
                    .foregroundColor(Theme.Colors.textSecondary)

                Spacer()

                Text("\(value >= 0 ? "+" : "")\(String(format: "%.1f", value))\(suffix)")
                    .font(Theme.Fonts.display(15))
                    .foregroundColor(color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.Colors.tertiary)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: max(0, geo.size.width * min(progress, 1.0)))
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Sleep Metric Box

/// Compact metric display for sleep summary
struct SleepMetricBox: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.Fonts.display(20))
                .foregroundColor(Theme.Colors.textPrimary)

            Text(label.uppercased())
                .font(Theme.Fonts.label(10))
                .tracking(0.5)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.Colors.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Week Selector

/// Navigation control for week selection
struct WeekSelector: View {
    let currentWeek: Date
    let onPreviousWeek: () -> Void
    let onNextWeek: () -> Void

    private var isNextWeekDisabled: Bool {
        WeekAggregator.isWeekInFuture(WeekAggregator.nextWeekStart(from: currentWeek))
    }

    var body: some View {
        HStack {
            Button(action: onPreviousWeek) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
            }

            Spacer()

            Text(WeekAggregator.formatWeekRange(currentWeek))
                .font(Theme.Fonts.label(15))
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()

            Button(action: onNextWeek) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isNextWeekDisabled ? Theme.Colors.textTertiary : Theme.Colors.textPrimary)
            }
            .disabled(isNextWeekDisabled)
        }
        .padding(.horizontal, Theme.Spacing.moduleP)
    }
}

// MARK: - Previews

#Preview("Recovery Gauge") {
    VStack(spacing: 40) {
        CircularProgressGauge(
            value: 78,
            color: Theme.Colors.recovery(score: 78),
            label: "Recovery",
            sublabel: "Peak"
        )
        .frame(width: 200, height: 200)

        CircularProgressGauge(
            value: 45,
            color: Theme.Colors.recovery(score: 45),
            label: "Recovery",
            sublabel: "Moderate"
        )
        .frame(width: 160, height: 160)
    }
    .padding()
    .background(Theme.Colors.primary)
}

#Preview("Strain Gauge") {
    StrainGauge(current: 12.5, target: 14.0)
        .frame(width: 180, height: 180)
        .padding()
        .background(Theme.Colors.primary)
}
