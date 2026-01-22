import SwiftUI

/// Session 7: Whoop-aligned Strain Tab
/// Focus on 0-21 scale with HR zone breakdown
struct StrainTab: View {
    @ObservedObject var viewModel: DashboardViewModel

    private var strainScore: Double {
        viewModel.strainScoreNormalized
    }

    private var activeCalories: Double {
        viewModel.todayMetrics?.activity?.activeEnergy ?? 0
    }

    private var zoneMinutes: [HRZone: Int] {
        guard let zones = viewModel.todayMetrics?.zoneDistribution else { return [:] }
        return [
            .zone1: zones.zone1Minutes,
            .zone2: zones.zone2Minutes,
            .zone3: zones.zone3Minutes,
            .zone4: zones.zone4Minutes,
            .zone5: zones.zone5Minutes
        ]
    }

    private var maxZoneMinutes: Int {
        max(zoneMinutes.values.max() ?? 1, 1)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.moduleP) {

                // Strain gauge with target ring
                StrainGauge(
                    current: strainScore,
                    target: viewModel.optimalStrainTarget ?? 14.0
                )
                .frame(width: 180, height: 180)

                // Raw contribution breakdown (NO POINTS SYSTEM)
                VStack(spacing: 12) {
                    StrainContributionRow(
                        label: "HR Zone Time",
                        value: "\(hrZoneTimeMinutes)min"
                    )
                    StrainContributionRow(
                        label: "Workout Duration",
                        value: "\(workoutDurationMinutes)min"
                    )
                    StrainContributionRow(
                        label: "Active Energy",
                        value: "\(Int(activeCalories)) cal"
                    )
                }
                .padding(.horizontal, Theme.Spacing.moduleP)

                // HR Zones: FULL WIDTH bars with minutes
                VStack(alignment: .leading, spacing: 12) {
                    Text("HR ZONES")
                        .font(Theme.Fonts.label(11))
                        .foregroundColor(Theme.Colors.textSecondary)

                    ForEach(HRZone.allCases, id: \.self) { zone in
                        HRZoneBar(
                            zone: zone,
                            minutes: zoneMinutes[zone] ?? 0,
                            maxMinutes: maxZoneMinutes
                        )
                    }
                }
                .padding(.horizontal, Theme.Spacing.moduleP)

                // Workout log
                if let workouts = viewModel.todayWorkouts, !workouts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("WORKOUTS")
                            .font(Theme.Fonts.label(11))
                            .foregroundColor(Theme.Colors.textSecondary)

                        ForEach(workouts) { workout in
                            WorkoutLogEntry(
                                type: workout.type,
                                timestamp: workout.startTime,
                                duration: workout.duration,
                                avgHR: workout.averageHeartRate
                            )
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.moduleP)
                }
            }
            .padding(.vertical, Theme.Spacing.moduleP)
        }
        .background(Theme.Colors.primary)
    }

    // MARK: - Computed Properties

    private var hrZoneTimeMinutes: Int {
        zoneMinutes.values.reduce(0, +)
    }

    private var workoutDurationMinutes: Int {
        viewModel.todayMetrics?.workouts?.totalDurationMinutes ?? 0
    }
}

// MARK: - Legacy Components (kept for backward compatibility)

struct StrainComponentsCard: View {
    let strain: StrainScore

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("STRAIN BREAKDOWN")
                .font(Theme.Fonts.label(11))
                .foregroundStyle(Theme.Colors.textTertiary)
                .tracking(1)

            ForEach(strain.components) { component in
                StrainComponentRow(component: component)
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

struct StrainComponentRow: View {
    let component: ScoreComponent

    var body: some View {
        HStack {
            Text(component.name.uppercased())
                .font(Theme.Fonts.label(10))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(1)

            Spacer()

            Text(component.formattedContribution)
                .font(Theme.Fonts.mono(12))
                .foregroundStyle(Theme.Colors.textPrimary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.Colors.borderSubtle)

                    Rectangle()
                        .fill(Theme.Colors.strainColor(for: component.normalizedValue / 5))
                }
            }
            .frame(width: 60, height: 4)
            .clipShape(Capsule())
        }
    }
}

struct ActivityStatCard: View {
    let icon: String
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Theme.Colors.neutral)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(Theme.Fonts.display(24))
                    .foregroundStyle(Theme.Colors.textPrimary)

                if !unit.isEmpty {
                    Text(unit)
                        .font(Theme.Fonts.label(10))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }

            Text(label)
                .font(Theme.Fonts.label(10))
                .foregroundStyle(Theme.Colors.textTertiary)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct HeartRateZonesCard: View {
    let zones: ZoneTimeDistribution

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("HEART RATE ZONES")
                .font(Theme.Fonts.label(11))
                .foregroundStyle(Theme.Colors.textTertiary)
                .tracking(1)

            VStack(spacing: Theme.Spacing.sm) {
                ZoneRow(zone: 5, label: "MAX", minutes: zones.zone5Minutes, color: Color(hex: "#DC2626"))
                ZoneRow(zone: 4, label: "HARD", minutes: zones.zone4Minutes, color: Color(hex: "#EF4444"))
                ZoneRow(zone: 3, label: "MODERATE", minutes: zones.zone3Minutes, color: Color(hex: "#F59E0B"))
                ZoneRow(zone: 2, label: "LIGHT", minutes: zones.zone2Minutes, color: Color(hex: "#4A9EFF"))
                ZoneRow(zone: 1, label: "REST", minutes: zones.zone1Minutes, color: Color(hex: "#10B981"))
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ZoneRow: View {
    let zone: Int
    let label: String
    let minutes: Int
    let color: Color

    var body: some View {
        HStack {
            Text("Z\(zone)")
                .font(Theme.Fonts.label(10))
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(Theme.Fonts.label(9))
                .foregroundStyle(Theme.Colors.textTertiary)
                .frame(width: 60, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.Colors.tertiary)

                    Rectangle()
                        .fill(color)
                        .frame(width: min(geo.size.width, geo.size.width * CGFloat(minutes) / 60))
                }
            }
            .frame(height: 8)
            .clipShape(Capsule())

            Text("\(minutes)m")
                .font(Theme.Fonts.display(10))
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(width: 36, alignment: .trailing)
        }
    }
}

#Preview {
    StrainTab(viewModel: DashboardViewModel(healthKitManager: HealthKitManager()))
        .preferredColorScheme(.dark)
}
