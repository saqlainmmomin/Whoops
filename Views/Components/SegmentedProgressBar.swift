import SwiftUI

/// Segmented progress bar for sleep stages and metric breakdowns
struct SegmentedProgressBar: View {
    let segments: [Segment]

    struct Segment: Identifiable {
        let id = UUID()
        let label: String
        let value: Double       // Percentage of total (0-1)
        let color: Color
    }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(segments) { segment in
                    if segment.value > 0 {
                        Rectangle()
                            .fill(segment.color)
                            .frame(width: max(geo.size.width * segment.value - 1, 2))
                    }
                }
            }
        }
        .frame(height: 8)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Sleep Stage Progress Bar

/// Pre-configured segmented bar for sleep stages
struct SleepStageProgressBar: View {
    let stages: SleepStages

    private var segments: [SegmentedProgressBar.Segment] {
        let total = Double(stages.totalMinutes)
        guard total > 0 else { return [] }

        return [
            SegmentedProgressBar.Segment(
                label: "Deep",
                value: Double(stages.deepMinutes) / total,
                color: Color(hex: "#5B21B6")  // Deep purple
            ),
            SegmentedProgressBar.Segment(
                label: "REM",
                value: Double(stages.remMinutes) / total,
                color: Color(hex: "#7C3AED")  // Purple
            ),
            SegmentedProgressBar.Segment(
                label: "Core",
                value: Double(stages.coreMinutes) / total,
                color: Color(hex: "#A78BFA")  // Light purple
            ),
            SegmentedProgressBar.Segment(
                label: "Awake",
                value: Double(stages.awakeMinutes) / total,
                color: Theme.Colors.textTertiary
            )
        ]
    }

    var body: some View {
        SegmentedProgressBar(segments: segments)
    }
}

// MARK: - HR Zone Progress Bar

/// Pre-configured segmented bar for HR zones
struct HRZoneProgressBar: View {
    let zoneMinutes: [HRZone: Int]

    private var totalMinutes: Int {
        zoneMinutes.values.reduce(0, +)
    }

    private var segments: [SegmentedProgressBar.Segment] {
        guard totalMinutes > 0 else { return [] }

        return HRZone.allCases.compactMap { zone in
            guard let minutes = zoneMinutes[zone], minutes > 0 else { return nil }
            return SegmentedProgressBar.Segment(
                label: zone.name,
                value: Double(minutes) / Double(totalMinutes),
                color: zoneColor(zone)
            )
        }
    }

    private func zoneColor(_ zone: HRZone) -> Color {
        switch zone {
        case .zone1: return Color(hex: "#10B981")  // Green - Recovery
        case .zone2: return Color(hex: "#4A9EFF")  // Blue - Endurance
        case .zone3: return Color(hex: "#F59E0B")  // Yellow - Tempo
        case .zone4: return Color(hex: "#EF4444")  // Red - Threshold
        case .zone5: return Color(hex: "#DC2626")  // Dark Red - Max
        }
    }

    var body: some View {
        SegmentedProgressBar(segments: segments)
    }
}

// MARK: - HR Zone Bar (Individual)

/// Individual HR zone bar for strain breakdown
struct HRZoneBar: View {
    let zone: HRZone
    let minutes: Int
    let maxMinutes: Int

    private var color: Color {
        switch zone {
        case .zone1: return Color(hex: "#10B981")
        case .zone2: return Color(hex: "#4A9EFF")
        case .zone3: return Color(hex: "#F59E0B")
        case .zone4: return Color(hex: "#EF4444")
        case .zone5: return Color(hex: "#DC2626")
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("Z\(zone.rawValue)")
                .font(Theme.Fonts.label(11))
                .foregroundColor(Theme.Colors.textSecondary)
                .frame(width: 24)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.Colors.tertiary)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: maxMinutes > 0
                               ? geo.size.width * CGFloat(minutes) / CGFloat(maxMinutes)
                               : 0)
                }
            }
            .frame(height: 16)

            Text("\(minutes)m")
                .font(Theme.Fonts.display(12))
                .foregroundColor(Theme.Colors.textPrimary)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

// MARK: - Strain Contribution Row

/// Row showing strain contribution breakdown
struct StrainContributionRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(Theme.Fonts.label(13))
                .foregroundColor(Theme.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(Theme.Fonts.display(15))
                .foregroundColor(Theme.Colors.textPrimary)
        }
    }
}

// MARK: - Workout Row

/// Row displaying a single workout
struct WorkoutRow: View {
    let workout: WorkoutEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: workoutIcon)
                .font(.system(size: 20))
                .foregroundColor(Theme.Colors.neutral)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.type)
                    .font(Theme.Fonts.label(14))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(workout.durationFormatted)
                    .font(Theme.Fonts.label(12))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()

            if let avgHR = workout.averageHeartRate {
                Text("\(Int(avgHR)) bpm")
                    .font(Theme.Fonts.display(14))
                    .foregroundColor(Theme.Colors.textPrimary)
            }
        }
        .padding(.vertical, 8)
    }

    private var workoutIcon: String {
        let type = workout.type.lowercased()
        if type.contains("run") { return "figure.run" }
        if type.contains("walk") { return "figure.walk" }
        if type.contains("cycle") || type.contains("bike") { return "bicycle" }
        if type.contains("swim") { return "figure.pool.swim" }
        if type.contains("yoga") { return "figure.yoga" }
        if type.contains("strength") || type.contains("weight") { return "dumbbell.fill" }
        if type.contains("hiit") { return "flame.fill" }
        return "figure.mixed.cardio"
    }
}

// MARK: - Workout Log Entry

/// Detailed workout log entry
struct WorkoutLogEntry: View {
    let type: String
    let timestamp: Date
    let duration: TimeInterval
    let avgHR: Double?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(type)
                    .font(Theme.Fonts.label(14))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(timestamp.formatted(.dateTime.hour().minute()))
                    .font(Theme.Fonts.label(11))
                    .foregroundColor(Theme.Colors.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                let minutes = Int(duration / 60)
                Text("\(minutes)min")
                    .font(Theme.Fonts.display(14))
                    .foregroundColor(Theme.Colors.textPrimary)

                if let hr = avgHR {
                    Text("\(Int(hr)) bpm avg")
                        .font(Theme.Fonts.label(11))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview("Segmented Progress Bar") {
    VStack(spacing: 20) {
        SegmentedProgressBar(segments: [
            .init(label: "Deep", value: 0.15, color: Color(hex: "#5B21B6")),
            .init(label: "REM", value: 0.22, color: Color(hex: "#7C3AED")),
            .init(label: "Core", value: 0.53, color: Color(hex: "#A78BFA")),
            .init(label: "Awake", value: 0.10, color: .gray)
        ])

        SegmentedProgressBar(segments: [
            .init(label: "Z1", value: 0.1, color: Color(hex: "#10B981")),
            .init(label: "Z2", value: 0.3, color: Color(hex: "#4A9EFF")),
            .init(label: "Z3", value: 0.4, color: Color(hex: "#F59E0B")),
            .init(label: "Z4", value: 0.15, color: Color(hex: "#EF4444")),
            .init(label: "Z5", value: 0.05, color: Color(hex: "#DC2626"))
        ])
    }
    .padding()
    .background(Theme.Colors.primary)
}
