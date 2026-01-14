import SwiftUI

// MARK: - Zone Distribution Card

struct ZoneDistributionCard: View {
    let distribution: ZoneTimeDistribution

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Heart Rate Zones")
                .font(.headline)

            // Visual bar
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    zoneBar(zone: .zone1, minutes: distribution.zone1Minutes, totalWidth: geometry.size.width)
                    zoneBar(zone: .zone2, minutes: distribution.zone2Minutes, totalWidth: geometry.size.width)
                    zoneBar(zone: .zone3, minutes: distribution.zone3Minutes, totalWidth: geometry.size.width)
                    zoneBar(zone: .zone4, minutes: distribution.zone4Minutes, totalWidth: geometry.size.width)
                    zoneBar(zone: .zone5, minutes: distribution.zone5Minutes, totalWidth: geometry.size.width)
                }
            }
            .frame(height: 24)
            .cornerRadius(4)

            // Legend
            VStack(spacing: 8) {
                zoneRow(.zone1, minutes: distribution.zone1Minutes)
                zoneRow(.zone2, minutes: distribution.zone2Minutes)
                zoneRow(.zone3, minutes: distribution.zone3Minutes)
                zoneRow(.zone4, minutes: distribution.zone4Minutes)
                zoneRow(.zone5, minutes: distribution.zone5Minutes)
            }

            HStack {
                Text("Total")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(distribution.totalMinutes) min")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func zoneBar(zone: HRZone, minutes: Int, totalWidth: CGFloat) -> some View {
        let total = distribution.totalMinutes
        let width = total > 0 ? (CGFloat(minutes) / CGFloat(total)) * totalWidth : 0

        return Rectangle()
            .fill(zoneColor(zone))
            .frame(width: max(width, minutes > 0 ? 4 : 0))
    }

    private func zoneRow(_ zone: HRZone, minutes: Int) -> some View {
        HStack {
            Circle()
                .fill(zoneColor(zone))
                .frame(width: 12, height: 12)

            Text(zone.name)
                .font(.caption)

            Spacer()

            Text("\(minutes) min")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("(\(Int(distribution.percentage(for: zone)))%)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
    }

    private func zoneColor(_ zone: HRZone) -> Color {
        switch zone {
        case .zone1: return .gray
        case .zone2: return .blue
        case .zone3: return .green
        case .zone4: return .orange
        case .zone5: return .red
        }
    }
}

// MARK: - Sleep Stage Breakdown Card

struct SleepStageBreakdownCard: View {
    let breakdown: SleepStageBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Stages")
                .font(.headline)

            // Visual bar
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    stageBar(stage: .deep, minutes: breakdown.deepMinutes, totalWidth: geometry.size.width)
                    stageBar(stage: .core, minutes: breakdown.coreMinutes, totalWidth: geometry.size.width)
                    stageBar(stage: .rem, minutes: breakdown.remMinutes, totalWidth: geometry.size.width)
                    stageBar(stage: .awake, minutes: breakdown.awakeMinutes, totalWidth: geometry.size.width)
                }
            }
            .frame(height: 24)
            .cornerRadius(4)

            // Breakdown rows
            VStack(spacing: 8) {
                stageRow(.deep, minutes: breakdown.deepMinutes, ideal: "13-23%", isInRange: breakdown.deepInRange)
                stageRow(.core, minutes: breakdown.coreMinutes, ideal: "50-60%", isInRange: breakdown.coreInRange)
                stageRow(.rem, minutes: breakdown.remMinutes, ideal: "20-25%", isInRange: breakdown.remInRange)
                if breakdown.awakeMinutes > 0 {
                    stageRow(.awake, minutes: breakdown.awakeMinutes, ideal: nil, isInRange: nil)
                }
            }

            HStack {
                Text("Total Asleep")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(formatMinutes(breakdown.totalAsleepMinutes))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func stageBar(stage: SleepStage, minutes: Int, totalWidth: CGFloat) -> some View {
        let total = breakdown.totalMinutes
        let width = total > 0 ? (CGFloat(minutes) / CGFloat(total)) * totalWidth : 0

        return Rectangle()
            .fill(stageColor(stage))
            .frame(width: max(width, minutes > 0 ? 4 : 0))
    }

    private func stageRow(_ stage: SleepStage, minutes: Int, ideal: String?, isInRange: Bool?) -> some View {
        HStack {
            Circle()
                .fill(stageColor(stage))
                .frame(width: 12, height: 12)

            Text(stage.rawValue)
                .font(.caption)

            if let ideal = ideal {
                Text("(ideal: \(ideal))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(formatMinutes(minutes))
                .font(.caption)
                .foregroundColor(.secondary)

            if let inRange = isInRange {
                Image(systemName: inRange ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .font(.caption)
                    .foregroundColor(inRange ? .green : .orange)
            }
        }
    }

    private func stageColor(_ stage: SleepStage) -> Color {
        switch stage {
        case .deep: return .indigo
        case .core: return .blue
        case .rem: return .cyan
        case .awake: return .orange
        case .unspecified: return .gray
        case .inBed: return .gray.opacity(0.5)
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 {
            return "\(h)h \(m)m"
        }
        return "\(m)m"
    }
}

// MARK: - Sleep Timing Card

struct SleepTimingCard: View {
    let bedtime: Date
    let wakeTime: Date
    let interruptions: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Timing")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bedtime")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(bedtime.formattedTime)
                        .font(.title3)
                        .fontWeight(.medium)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Wake Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(wakeTime.formattedTime)
                        .font(.title3)
                        .fontWeight(.medium)
                }
            }

            Divider()

            HStack {
                Image(systemName: "moon.zzz")
                    .foregroundColor(.secondary)
                Text("Interruptions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(interruptions)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - HR Recovery Card

struct HRRecoveryCard: View {
    let recovery: HRRecoveryData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Heart Rate Recovery")
                .font(.headline)

            HStack {
                Text("Peak HR")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(recovery.peakHR)) bpm")
                    .font(.subheadline)
            }

            if let drop1 = recovery.recovery1Min {
                HStack {
                    Text("1-min recovery")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("-\(Int(drop1)) bpm")
                        .font(.subheadline)
                        .foregroundColor(drop1 >= 12 ? .green : .orange)
                }
            }

            if let drop2 = recovery.recovery2Min {
                HStack {
                    Text("2-min recovery")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("-\(Int(drop2)) bpm")
                        .font(.subheadline)
                }
            }

            HStack {
                Text("Quality")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(recovery.recoveryQuality.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(recoveryQualityColor)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var recoveryQualityColor: Color {
        switch recovery.recoveryQuality {
        case .excellent: return .green
        case .good: return .blue
        case .average: return .yellow
        case .belowAverage: return .orange
        case .unknown: return .gray
        }
    }
}

// MARK: - Workout Summary Card

struct WorkoutSummaryCard: View {
    let summary: DailyWorkoutSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Workouts")
                    .font(.headline)
                Spacer()
                Text("\(summary.totalWorkouts)")
                    .font(.headline)
            }

            ForEach(summary.workouts) { workout in
                HStack {
                    Image(systemName: workout.activityType.icon)
                        .foregroundColor(.blue)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.activityType.rawValue)
                            .font(.subheadline)
                        Text(workout.formattedDuration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if let energy = workout.totalEnergyBurned {
                        Text("\(Int(energy)) kcal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Text("Total Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(summary.totalDurationMinutes) min")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Total Energy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(summary.totalEnergyBurned)) kcal")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            ZoneDistributionCard(
                distribution: ZoneTimeDistribution(
                    zone1Minutes: 10,
                    zone2Minutes: 15,
                    zone3Minutes: 20,
                    zone4Minutes: 10,
                    zone5Minutes: 5
                )
            )

            SleepStageBreakdownCard(
                breakdown: SleepStageBreakdown(
                    deepMinutes: 60,
                    coreMinutes: 180,
                    remMinutes: 90,
                    awakeMinutes: 15
                )
            )

            SleepTimingCard(
                bedtime: Date().adding(hours: -8),
                wakeTime: Date(),
                interruptions: 2
            )
        }
        .padding()
    }
}
