import SwiftUI

/// Info sheet explaining metric calculations and normal ranges
struct MetricInfoSheet: View {
    let metric: MetricType
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title with icon
                    HStack(spacing: 12) {
                        Image(systemName: metric.icon)
                            .font(.system(size: 32))
                            .foregroundColor(metric.themeColor)

                        Text(metric.displayName)
                            .font(Theme.Fonts.display(28))
                            .foregroundColor(Theme.Colors.textPrimary)
                    }

                    // Calculation explanation
                    VStack(alignment: .leading, spacing: 8) {
                        Text("HOW IT'S CALCULATED")
                            .font(Theme.Fonts.label(11))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .tracking(1)

                        Text(metric.calculationExplanation)
                            .font(Theme.Fonts.body)
                            .foregroundColor(Theme.Colors.textPrimary)
                    }

                    // Normal ranges
                    VStack(alignment: .leading, spacing: 12) {
                        Text("NORMAL RANGES")
                            .font(Theme.Fonts.label(11))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .tracking(1)

                        ForEach(metric.ranges, id: \.label) { range in
                            HStack {
                                Circle()
                                    .fill(range.color)
                                    .frame(width: 8, height: 8)

                                Text(range.label)
                                    .font(Theme.Fonts.body)
                                    .foregroundColor(Theme.Colors.textPrimary)

                                Spacer()

                                Text(range.valueRange)
                                    .font(Theme.Fonts.label(13))
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                        }
                    }

                    // Actionable guidance
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WHAT IT MEANS")
                            .font(Theme.Fonts.label(11))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .tracking(1)

                        Text(metric.actionableGuidance)
                            .font(Theme.Fonts.body)
                            .foregroundColor(Theme.Colors.textPrimary)
                    }

                    // Tips section
                    if !metric.tips.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("TIPS")
                                .font(Theme.Fonts.label(11))
                                .foregroundColor(Theme.Colors.textSecondary)
                                .tracking(1)

                            ForEach(metric.tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.Colors.caution)

                                    Text(tip)
                                        .font(Theme.Fonts.body)
                                        .foregroundColor(Theme.Colors.textPrimary)
                                }
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.moduleP)
            }
            .background(Theme.Colors.primary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.neutral)
                }
            }
        }
    }
}

// MARK: - MetricType Extensions

extension MetricType {
    var displayName: String {
        rawValue
    }

    var themeColor: Color {
        switch self {
        case .recovery: return Theme.Colors.optimal
        case .strain: return Theme.Colors.caution
        case .sleep: return Theme.Colors.neutral
        case .heartRate: return Theme.Colors.critical
        case .hrv: return Theme.Colors.neutral
        case .activity: return Theme.Colors.caution
        }
    }

    var calculationExplanation: String {
        switch self {
        case .recovery:
            return "Recovery is calculated from HRV deviation (50%), resting heart rate deviation (30%), and sleep performance (20%). Higher scores indicate better readiness for physical activity."

        case .strain:
            return "Strain measures cardiovascular load on a 0-21 scale. It accounts for time spent in elevated heart rate zones, workout intensity, and active energy expenditure."

        case .sleep:
            return "Sleep performance combines hours slept vs. needed (40%), sleep efficiency (30%), and schedule consistency (30%). Tracked automatically using Apple Watch motion and heart rate data."

        case .heartRate:
            return "Resting heart rate is measured during your deepest sleep. Lower values generally indicate better cardiovascular fitness. Trends matter more than single readings."

        case .hrv:
            return "Heart Rate Variability measures the variation in time between heartbeats. It reflects autonomic nervous system balance and stress resilience."

        case .activity:
            return "Activity metrics include steps, active calories, and workout sessions tracked through Apple Watch and iPhone sensors."
        }
    }

    var actionableGuidance: String {
        switch self {
        case .recovery:
            return "Use recovery to guide training intensity. Green (70-100%) means you're ready for hard training. Yellow (34-69%) suggests moderate activity. Red (<34%) indicates rest is needed."

        case .strain:
            return "Strain builds throughout the day with activity. Match your strain to your recovery - higher recovery allows higher strain targets. Overreaching with low recovery can impair adaptation."

        case .sleep:
            return "Consistent sleep schedules and 7-9 hours nightly optimize recovery. Poor sleep compounds over time as sleep debt. Alcohol and late meals reduce sleep quality."

        case .heartRate:
            return "A rising RHR trend may indicate accumulated fatigue, illness onset, or dehydration. A declining trend suggests improved fitness or recovery."

        case .hrv:
            return "Higher HRV (>60ms) indicates better stress resilience. Impacted by sleep quality, alcohol, illness, and overtraining. Day-to-day variation is normal; focus on 7-day trends."

        case .activity:
            return "Regular activity improves cardiovascular health and recovery capacity. Balance activity with adequate rest based on your recovery score."
        }
    }

    var ranges: [MetricRange] {
        switch self {
        case .recovery:
            return [
                MetricRange(label: "Optimal", valueRange: "70-100%", color: Theme.Colors.optimal),
                MetricRange(label: "Moderate", valueRange: "34-69%", color: Theme.Colors.caution),
                MetricRange(label: "Low", valueRange: "0-33%", color: Theme.Colors.critical)
            ]

        case .strain:
            return [
                MetricRange(label: "Light", valueRange: "0-9", color: Theme.Colors.neutral),
                MetricRange(label: "Moderate", valueRange: "10-13", color: Theme.Colors.optimal),
                MetricRange(label: "High", valueRange: "14-17", color: Theme.Colors.caution),
                MetricRange(label: "All Out", valueRange: "18-21", color: Theme.Colors.critical)
            ]

        case .sleep:
            return [
                MetricRange(label: "Excellent", valueRange: "80-100%", color: Theme.Colors.optimal),
                MetricRange(label: "Good", valueRange: "60-79%", color: Theme.Colors.neutral),
                MetricRange(label: "Poor", valueRange: "0-59%", color: Theme.Colors.critical)
            ]

        case .heartRate:
            return [
                MetricRange(label: "Athletic", valueRange: "40-55 bpm", color: Theme.Colors.optimal),
                MetricRange(label: "Normal", valueRange: "56-70 bpm", color: Theme.Colors.neutral),
                MetricRange(label: "Elevated", valueRange: "71-100 bpm", color: Theme.Colors.caution)
            ]

        case .hrv:
            return [
                MetricRange(label: "High", valueRange: ">60 ms", color: Theme.Colors.optimal),
                MetricRange(label: "Normal", valueRange: "30-60 ms", color: Theme.Colors.neutral),
                MetricRange(label: "Low", valueRange: "<30 ms", color: Theme.Colors.caution)
            ]

        case .activity:
            return [
                MetricRange(label: "Active", valueRange: ">10k steps", color: Theme.Colors.optimal),
                MetricRange(label: "Moderate", valueRange: "5-10k steps", color: Theme.Colors.neutral),
                MetricRange(label: "Sedentary", valueRange: "<5k steps", color: Theme.Colors.caution)
            ]
        }
    }

    var tips: [String] {
        switch self {
        case .recovery:
            return [
                "Prioritize sleep quality for best recovery",
                "Avoid alcohol and late meals before bed",
                "Match training intensity to recovery level"
            ]

        case .strain:
            return [
                "Build strain gradually throughout the day",
                "High strain requires adequate recovery time",
                "Zone 4-5 time contributes most to strain"
            ]

        case .sleep:
            return [
                "Keep a consistent bedtime and wake time",
                "Avoid screens 1 hour before bed",
                "Keep your bedroom cool and dark"
            ]

        case .heartRate:
            return [
                "Measure at the same time daily for consistency",
                "Morning readings after waking are most reliable",
                "Hydration affects heart rate"
            ]

        case .hrv:
            return [
                "Measure HRV at the same time each day",
                "5+ minute readings are most accurate",
                "Stress and caffeine reduce HRV"
            ]

        case .activity:
            return [
                "Aim for at least 30 minutes of moderate activity daily",
                "Break up long periods of sitting",
                "Mix cardio with strength training"
            ]
        }
    }
}

// MARK: - Supporting Types

struct MetricRange {
    let label: String
    let valueRange: String
    let color: Color
}

// MARK: - Preview

#Preview("Metric Info Sheet") {
    MetricInfoSheet(metric: .hrv)
}
