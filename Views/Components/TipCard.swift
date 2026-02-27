import SwiftUI

/// Whoop-style tip/recommendation card
/// Shows contextual advice with lightbulb icon
struct TipCard: View {
    let title: String
    let message: String
    var icon: String = "lightbulb.fill"
    var accentColor: Color = Theme.Colors.whoopTeal

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(accentColor)
                .frame(width: 24)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.Fonts.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(message)
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(Theme.Dimensions.cardPadding)
        .background(Theme.Colors.cardBackgroundAlt)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cardCornerRadius))
    }
}

/// Pre-built sleep tips
struct SleepTips {
    static func needMoreSleep(deficit: Double) -> TipCard {
        TipCard(
            title: "Try to get more sleep",
            message: "Going to bed earlier can improve your recovery score and daily performance."
        )
    }

    static func maintainConsistency() -> TipCard {
        TipCard(
            title: "Keep your schedule consistent",
            message: "Maintaining a regular sleep schedule helps optimize your circadian rhythm."
        )
    }

    static func reduceScreenTime() -> TipCard {
        TipCard(
            title: "Reduce screen time before bed",
            message: "Limiting blue light exposure 1-2 hours before sleep can improve sleep quality.",
            icon: "moon.stars.fill"
        )
    }

    static func greatJob() -> TipCard {
        TipCard(
            title: "Great sleep habits!",
            message: "You're meeting your sleep needs. Keep up the consistent routine.",
            icon: "checkmark.circle.fill"
        )
    }
}

/// Pre-built recovery tips
struct RecoveryTips {
    static func lowRecovery() -> TipCard {
        TipCard(
            title: "Prioritize rest today",
            message: "Your body is signaling it needs more recovery. Consider lighter activities.",
            accentColor: Theme.Colors.whoopOrange
        )
    }

    static func hydrate() -> TipCard {
        TipCard(
            title: "Stay hydrated",
            message: "Proper hydration supports recovery and helps maintain HRV levels.",
            icon: "drop.fill"
        )
    }
}

/// Pre-built strain tips
struct StrainTips {
    static func underTarget() -> TipCard {
        TipCard(
            title: "Room for more activity",
            message: "You're below your optimal strain target. Consider adding movement to your day.",
            icon: "figure.walk"
        )
    }

    static func overTarget() -> TipCard {
        TipCard(
            title: "You've pushed hard today",
            message: "Make sure to prioritize sleep and nutrition to support your recovery.",
            icon: "exclamationmark.triangle.fill",
            accentColor: Theme.Colors.whoopOrange
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        TipCard(
            title: "Try to get more sleep",
            message: "Going to bed earlier can improve your recovery score and daily performance."
        )

        SleepTips.maintainConsistency()

        RecoveryTips.lowRecovery()

        StrainTips.underTarget()
    }
    .padding()
    .background(Theme.Colors.primary)
}
