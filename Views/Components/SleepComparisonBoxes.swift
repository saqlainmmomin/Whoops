import SwiftUI

/// Whoop-style sleep comparison boxes
/// Shows "Hours of Sleep" vs "Sleep Needed" side by side
struct SleepComparisonBoxes: View {
    let hoursSlept: String
    let hoursNeeded: String

    var body: some View {
        HStack(spacing: 12) {
            // Hours of Sleep (white background)
            SleepComparisonBox(
                value: hoursSlept,
                label: "HOURS OF SLEEP",
                style: .standard
            )

            // Sleep Needed (teal accent)
            SleepComparisonBox(
                value: hoursNeeded,
                label: "SLEEP NEEDED",
                style: .accent
            )
        }
    }
}

/// Individual sleep comparison box
struct SleepComparisonBox: View {
    enum Style {
        case standard
        case accent
    }

    let value: String
    let label: String
    let style: Style

    private var backgroundColor: Color {
        switch style {
        case .standard:
            return Theme.Colors.cardBackground
        case .accent:
            return Theme.Colors.whoopTeal.opacity(0.15)
        }
    }

    private var borderColor: Color {
        switch style {
        case .standard:
            return Theme.Colors.borderSubtle
        case .accent:
            return Theme.Colors.whoopTeal.opacity(0.3)
        }
    }

    private var labelColor: Color {
        switch style {
        case .standard:
            return Theme.Colors.textSecondary
        case .accent:
            return Theme.Colors.whoopTeal
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Gap S-3: Large value (~48pt per DESIGN_SPEC largeValue)
            Text(value)
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundColor(style == .accent ? Theme.Colors.whoopTeal : Theme.Colors.textPrimary)

            // Gap S-3: Label in outlined capsule badge below value
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(labelColor)
                .tracking(0.5)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .overlay(
                    Capsule()
                        .strokeBorder(labelColor.opacity(0.5), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Dimensions.cardCornerRadius)
                .strokeBorder(borderColor, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 24) {
        SleepComparisonBoxes(
            hoursSlept: "5:51",
            hoursNeeded: "8:52"
        )

        SleepComparisonBoxes(
            hoursSlept: "7:30",
            hoursNeeded: "7:45"
        )
    }
    .padding()
    .background(Theme.Colors.primary)
}
