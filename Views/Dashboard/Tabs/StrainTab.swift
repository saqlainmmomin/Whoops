import SwiftUI

struct StrainTab: View {
    @ObservedObject var viewModel: DashboardViewModel

    private var strainScore: Double {
        viewModel.strainScoreNormalized
    }

    private var activeCalories: Double {
        viewModel.todayMetrics?.activity?.activeEnergy ?? 0
    }

    private var steps: Int {
        viewModel.todayMetrics?.activity?.steps ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Main strain arc
                StrainArc(
                    score: strainScore,
                    targetStrain: viewModel.optimalStrainTarget,
                    weeklyAverage: viewModel.weeklyStrainAvg
                )
                .padding(.top, Theme.Spacing.lg)

                // Strain components
                if let strain = viewModel.todayMetrics?.strainScore {
                    StrainComponentsCard(strain: strain)
                        .padding(.horizontal)
                }

                // Activity stats
                HStack(spacing: Theme.Spacing.md) {
                    ActivityStatCard(
                        icon: "flame.fill",
                        value: String(format: "%.0f", activeCalories),
                        unit: "cal",
                        label: "ACTIVE"
                    )

                    ActivityStatCard(
                        icon: "figure.walk",
                        value: formatSteps(steps),
                        unit: "",
                        label: "STEPS"
                    )
                }
                .padding(.horizontal)

                // Heart rate zones
                if let zones = viewModel.todayMetrics?.zoneDistribution {
                    HeartRateZonesCard(zones: zones)
                        .padding(.horizontal)
                }

                // Weekly trend
                if !viewModel.strainSparklineData.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("7-DAY STRAIN TREND")
                            .font(Theme.Fonts.label(11))
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .tracking(1)

                        SparklineChart(
                            data: viewModel.strainSparklineData,
                            color: Theme.Colors.strainColor(for: strainScore)
                        )
                        .frame(height: 60)
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: Theme.Spacing.xl)
            }
            .padding(.vertical, Theme.Spacing.lg)
        }
        .background(Theme.Colors.void)
    }

    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            return String(format: "%.1fk", Double(steps) / 1000)
        }
        return "\(steps)"
    }
}

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
                .foregroundStyle(Theme.Colors.strainModerate)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(Theme.Fonts.mono(24))
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
        .background(Theme.Colors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Theme.Colors.borderSubtle, lineWidth: 1)
        )
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
                ZoneRow(zone: 4, label: "HARD", minutes: zones.zone4Minutes, color: Color(hex: "#F97316"))
                ZoneRow(zone: 3, label: "MODERATE", minutes: zones.zone3Minutes, color: Color(hex: "#FBBF24"))
                ZoneRow(zone: 2, label: "LIGHT", minutes: zones.zone2Minutes, color: Color(hex: "#34D399"))
                ZoneRow(zone: 1, label: "REST", minutes: zones.zone1Minutes, color: Color(hex: "#6B7280"))
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

struct ZoneRow: View {
    let zone: Int
    let label: String
    let minutes: Int
    let color: Color

    private var totalMinutes: Int { max(minutes, 1) }

    var body: some View {
        HStack {
            Text("Z\(zone)")
                .font(Theme.Fonts.mono(10))
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(Theme.Fonts.label(9))
                .foregroundStyle(Theme.Colors.textTertiary)
                .frame(width: 60, alignment: .leading)

            GeometryReader { geo in
                Rectangle()
                    .fill(color)
                    .frame(width: min(geo.size.width, geo.size.width * CGFloat(minutes) / 60))
            }
            .frame(height: 8)
            .background(Theme.Colors.borderSubtle)
            .clipShape(Capsule())

            Text("\(minutes)m")
                .font(Theme.Fonts.mono(10))
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(width: 36, alignment: .trailing)
        }
    }
}

#Preview {
    StrainTab(viewModel: DashboardViewModel(healthKitManager: HealthKitManager()))
        .preferredColorScheme(.dark)
}
