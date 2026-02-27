import SwiftUI

/// WHOOP-style strain activity row
/// Badge with strain value on left, activity name, time range on right
struct StrainActivityRow: View {
    let strainValue: Double
    let activityType: String
    let timeRange: String
    let calories: Int?
    let duration: String?

    var body: some View {
        HStack(spacing: 12) {
            // Strain badge (cyan pill with icon)
            HStack(spacing: 6) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)

                Text(String(format: "%.1f", strainValue))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Theme.Colors.whoopCyan)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Activity name
            Text(activityType.uppercased())
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)
                .tracking(0.5)

            Spacer()

            // Time details
            VStack(alignment: .trailing, spacing: 2) {
                Text(extractEndTime(from: timeRange))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(extractStartTime(from: timeRange))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Theme.Colors.textTertiary)
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.Colors.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cardCornerRadius))
    }

    private func extractEndTime(from range: String) -> String {
        let parts = range.components(separatedBy: " - ")
        return parts.count > 1 ? parts[1] : range
    }

    private func extractStartTime(from range: String) -> String {
        let parts = range.components(separatedBy: " - ")
        return parts.first ?? ""
    }
}

/// Strain value badge (standalone)
struct StrainBadge: View {
    let value: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 10, weight: .bold))
            Text(String(format: "%.1f", value))
                .font(.system(size: 14, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.Colors.whoopCyan)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// WHOOP-style sleep activity row
/// Moon icon with duration badge, "SLEEP" label, time range on right
struct SleepActivityRow: View {
    let bedtime: String
    let wakeTime: String
    let duration: String
    let quality: String?

    var body: some View {
        HStack(spacing: 12) {
            // Sleep badge (blue/purple pill with moon and duration)
            HStack(spacing: 6) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)

                Text(duration)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Theme.Colors.stageDeep)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // "SLEEP" label
            Text("SLEEP")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)
                .tracking(0.5)

            Spacer()

            // Time details
            VStack(alignment: .trailing, spacing: 2) {
                Text(wakeTime)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(bedtime)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Theme.Colors.textTertiary)
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.Colors.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cardCornerRadius))
    }
}

/// General activity row for Overview tab
struct ActivityRow: View {
    let icon: String
    let activityType: String
    let timeRange: String
    let detail: String?
    var iconColor: Color = Theme.Colors.whoopTeal

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 28)

            // Activity details
            VStack(alignment: .leading, spacing: 2) {
                Text(activityType.uppercased())
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .tracking(0.3)

                Text(timeRange)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()

            if let detail = detail {
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.Colors.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cardCornerRadius))
    }
}

#Preview {
    VStack(spacing: 12) {
        StrainActivityRow(
            strainValue: 11.8,
            activityType: "Functional Fitness",
            timeRange: "4:22 PM - 5:25 PM",
            calories: 450,
            duration: "1h 03m"
        )

        SleepActivityRow(
            bedtime: "[Sun] 10:12 PM",
            wakeTime: "4:47 AM",
            duration: "5:51",
            quality: nil
        )

        ActivityRow(
            icon: "figure.run",
            activityType: "Running",
            timeRange: "7:30 AM - 8:15 AM",
            detail: "45 min"
        )
    }
    .padding()
    .background(Theme.Colors.primary)
}
