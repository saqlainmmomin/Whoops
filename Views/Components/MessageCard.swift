import SwiftUI

/// Whoop-style message card for Recovery/Strain insights
/// Displays a title and personalized message
struct MessageCard: View {
    let title: String
    let message: String
    var accentColor: Color = Theme.Colors.whoopTeal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.Fonts.mediumValue)
                .foregroundColor(Theme.Colors.textPrimary)

            Text(message)
                .font(Theme.Fonts.body)
                .foregroundColor(Theme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Dimensions.cardPadding)
        .background(
            ZStack(alignment: .leading) {
                Theme.Colors.cardBackground

                // Subtle accent bar on left
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 3)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cardCornerRadius))
    }
}

/// Recovery-specific message generator
struct RecoveryMessage {
    static func generate(score: Int) -> (title: String, message: String) {
        switch score {
        case 85...100:
            return (
                "Peak Recovery",
                "Your body is fully recovered. Today is ideal for high-intensity training or competition."
            )
        case 67..<85:
            return (
                "Solid Recovery",
                "Your body is well-recovered. You can handle moderate to high strain activities today."
            )
        case 34..<67:
            return (
                "Moderate Recovery",
                "Your body is partially recovered. Consider lighter activities and prioritize sleep tonight."
            )
        default:
            return (
                "Low Recovery",
                "Your body needs more rest. Focus on recovery activities and avoid intense training."
            )
        }
    }
}

/// Strain-specific message generator
struct StrainMessage {
    static func generate(current: Double, target: Double) -> (title: String, message: String) {
        let ratio = current / max(target, 0.1)

        if ratio < 0.5 {
            return (
                "Light Strain",
                "You're below your optimal strain target. Consider adding more activity to meet your goals."
            )
        } else if ratio < 1.0 {
            return (
                "Building Strain",
                "You're approaching your optimal strain target. Keep up the good work."
            )
        } else if ratio < 1.2 {
            return (
                "Balanced Strain",
                "You've hit your optimal strain target for your recovery level. Well done!"
            )
        } else {
            return (
                "High Strain",
                "You've exceeded your optimal strain target. Make sure to prioritize recovery tonight."
            )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageCard(
            title: "Solid Recovery",
            message: "Your body is well-recovered. You can handle moderate to high strain activities today.",
            accentColor: Theme.Colors.whoopYellow
        )

        MessageCard(
            title: "Balanced Strain",
            message: "You've hit your optimal strain target for your recovery level. Well done!",
            accentColor: Theme.Colors.whoopCyan
        )

        MessageCard(
            title: "Low Recovery",
            message: "Your body needs more rest. Focus on recovery activities and avoid intense training.",
            accentColor: Color(hex: "#FF3B30")
        )
    }
    .padding()
    .background(Theme.Colors.primary)
}
