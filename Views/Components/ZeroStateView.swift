import SwiftUI

/// Zero-state view for when data is unavailable
/// Shows appropriate icon and helpful message per metric type
struct ZeroStateView: View {
    let metric: MetricType
    let message: String

    // MARK: - Factory Methods

    static func rhr() -> ZeroStateView {
        ZeroStateView(
            metric: .heartRate,
            message: "No resting heart rate data available. Ensure Apple Watch is worn during sleep."
        )
    }

    static func hrv() -> ZeroStateView {
        ZeroStateView(
            metric: .hrv,
            message: "Insufficient data. Requires 4+ hours of sleep with Apple Watch."
        )
    }

    static func noWorkouts() -> ZeroStateView {
        ZeroStateView(
            metric: .strain,
            message: "No activity logged today"
        )
    }

    static func noSleep() -> ZeroStateView {
        ZeroStateView(
            metric: .sleep,
            message: "No sleep data recorded. Wear Apple Watch to bed for sleep tracking."
        )
    }

    static func noRecovery() -> ZeroStateView {
        ZeroStateView(
            metric: .recovery,
            message: "Insufficient data for recovery score. Requires sleep and heart rate data."
        )
    }

    static func noActivity() -> ZeroStateView {
        ZeroStateView(
            metric: .activity,
            message: "No activity data available"
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: metric.icon)
                .font(.system(size: 32))
                .foregroundColor(Theme.Colors.textTertiary)

            Text(message)
                .font(Theme.Fonts.body)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.moduleP)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Compact Zero State

/// Inline zero state for smaller spaces
struct CompactZeroState: View {
    let icon: String
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.textTertiary)

            Text(message)
                .font(Theme.Fonts.label(13))
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Loading State

/// Loading placeholder view
struct LoadingStateView: View {
    let message: String

    init(message: String = "Loading data...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.neutral))

            Text(message)
                .font(Theme.Fonts.body)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding(Theme.Spacing.moduleP)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Permission Required State

/// View shown when HealthKit permission is needed
struct PermissionRequiredView: View {
    let onRequestPermission: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.neutral)

            Text("Health Access Required")
                .font(Theme.Fonts.label(17))
                .foregroundColor(Theme.Colors.textPrimary)

            Text("Enable Health access to view your recovery, strain, and sleep metrics.")
                .font(Theme.Fonts.body)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: onRequestPermission) {
                Text("Grant Access")
                    .font(Theme.Fonts.label(15))
                    .foregroundColor(Theme.Colors.primary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.Colors.neutral)
                    .clipShape(Capsule())
            }
        }
        .padding(Theme.Spacing.moduleP)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview("Zero States") {
    ScrollView {
        VStack(spacing: 16) {
            ZeroStateView.hrv()
            ZeroStateView.rhr()
            ZeroStateView.noWorkouts()
            ZeroStateView.noSleep()

            CompactZeroState(
                icon: "waveform.path.ecg",
                message: "No HRV data"
            )

            LoadingStateView()

            PermissionRequiredView(onRequestPermission: { })
        }
        .padding()
    }
    .background(Theme.Colors.primary)
}
