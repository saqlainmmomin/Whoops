import SwiftUI

/// Insight card for contextual recommendations
/// Clean design with NO gradient backgrounds
struct InsightCard: View {
    let icon: String
    let heading: String
    let bodyText: String
    let accentColor: Color

    init(icon: String, heading: String, body: String, accentColor: Color) {
        self.icon = icon
        self.heading = heading
        self.bodyText = body
        self.accentColor = accentColor
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(heading)
                    .font(Theme.Fonts.label(15))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(bodyText)
                    .font(Theme.Fonts.body)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.moduleP)
        .background(Theme.Colors.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        // NO GRADIENT BACKGROUNDS
    }
}

// MARK: - Primary Insight Model

/// Model for dashboard insights
struct PrimaryInsight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let message: String
    let color: Color

    /// Create recovery-based insight
    static func recovery(score: Int, hrvDeviation: Double) -> PrimaryInsight {
        if score >= 70 {
            return PrimaryInsight(
                icon: "checkmark.circle.fill",
                title: "Ready for Training",
                message: "Good recovery indicators. Your body can handle high intensity today.",
                color: Theme.Colors.optimal
            )
        } else if score >= 34 {
            if hrvDeviation < -10 {
                return PrimaryInsight(
                    icon: "waveform.path.ecg",
                    title: "HRV Below Baseline",
                    message: "Consider stress reduction techniques and ensure adequate sleep.",
                    color: Theme.Colors.caution
                )
            }
            return PrimaryInsight(
                icon: "figure.walk",
                title: "Moderate Activity OK",
                message: "You're partially recovered. Moderate intensity training is appropriate.",
                color: Theme.Colors.neutral
            )
        } else {
            return PrimaryInsight(
                icon: "bed.double.fill",
                title: "Prioritize Rest",
                message: "Your body shows signs of incomplete recovery. Consider light activity only.",
                color: Theme.Colors.critical
            )
        }
    }

    /// Create sleep-based insight
    static func sleep(performance: Int, consistency: Double) -> PrimaryInsight {
        if performance >= 80 {
            return PrimaryInsight(
                icon: "moon.fill",
                title: "Great Sleep",
                message: "Excellent sleep quality. Your body is well-rested.",
                color: Theme.Colors.optimal
            )
        } else if consistency < 0.6 {
            return PrimaryInsight(
                icon: "clock.fill",
                title: "Improve Consistency",
                message: "Try to maintain a more consistent sleep schedule for better recovery.",
                color: Theme.Colors.caution
            )
        } else if performance >= 60 {
            return PrimaryInsight(
                icon: "moon.zzz.fill",
                title: "Sleep Could Be Better",
                message: "Consider getting to bed earlier to hit your sleep target.",
                color: Theme.Colors.neutral
            )
        } else {
            return PrimaryInsight(
                icon: "exclamationmark.triangle.fill",
                title: "Sleep Deficit",
                message: "Prioritize sleep tonight. Poor sleep affects recovery and performance.",
                color: Theme.Colors.critical
            )
        }
    }

    /// Create strain-based insight
    static func strain(current: Double, target: Double, recovery: Int) -> PrimaryInsight {
        let ratio = current / max(target, 0.1)

        if ratio > 1.2 && recovery < 50 {
            return PrimaryInsight(
                icon: "exclamationmark.triangle.fill",
                title: "Overreaching",
                message: "Strain significantly exceeds recovery. Rest recommended.",
                color: Theme.Colors.critical
            )
        } else if ratio > 1.0 {
            return PrimaryInsight(
                icon: "flame.fill",
                title: "Target Exceeded",
                message: "You've hit your strain target. Consider winding down.",
                color: Theme.Colors.caution
            )
        } else if ratio > 0.5 {
            return PrimaryInsight(
                icon: "checkmark.circle.fill",
                title: "Good Progress",
                message: "You're on track to hit your optimal strain target.",
                color: Theme.Colors.optimal
            )
        } else {
            return PrimaryInsight(
                icon: "figure.run",
                title: "Room for Activity",
                message: "You have capacity for more activity today based on your recovery.",
                color: Theme.Colors.neutral
            )
        }
    }
}

// MARK: - Expanded Insight Card

/// Card with optional action button
struct ExpandedInsightCard: View {
    let insight: PrimaryInsight
    let action: (() -> Void)?
    let actionLabel: String?

    init(
        insight: PrimaryInsight,
        action: (() -> Void)? = nil,
        actionLabel: String? = nil
    ) {
        self.insight = insight
        self.action = action
        self.actionLabel = actionLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: insight.icon)
                    .font(.system(size: 24))
                    .foregroundColor(insight.color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(Theme.Fonts.label(15))
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text(insight.message)
                        .font(Theme.Fonts.body)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            if let action, let label = actionLabel {
                Button(action: action) {
                    Text(label)
                        .font(Theme.Fonts.label(13))
                        .foregroundColor(insight.color)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(insight.color.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(Theme.Spacing.moduleP)
        .background(Theme.Colors.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview("Insight Cards") {
    ScrollView {
        VStack(spacing: 16) {
            InsightCard(
                icon: "checkmark.circle.fill",
                heading: "Ready for Training",
                body: "Good recovery indicators. Your body can handle high intensity today.",
                accentColor: Theme.Colors.optimal
            )

            InsightCard(
                icon: "waveform.path.ecg",
                heading: "HRV Below Baseline",
                body: "Consider stress reduction techniques and ensure adequate sleep.",
                accentColor: Theme.Colors.caution
            )

            InsightCard(
                icon: "bed.double.fill",
                heading: "Prioritize Rest",
                body: "Your body shows signs of incomplete recovery. Light activity only.",
                accentColor: Theme.Colors.critical
            )

            ExpandedInsightCard(
                insight: PrimaryInsight.recovery(score: 78, hrvDeviation: 12),
                action: { },
                actionLabel: "View Details"
            )
        }
        .padding()
    }
    .background(Theme.Colors.primary)
}
