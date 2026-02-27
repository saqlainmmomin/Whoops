import SwiftUI

/// Whoop-style alarm and bedtime planning row
/// Shows "ALARM ON" status and "PLAN BEDTIME" CTA
/// Integrates with AlarmManager for actual functionality
struct AlarmBedtimeRow: View {
    @StateObject private var alarmManager = AlarmManager.shared
    @State private var showAlarmSettings = false

    var body: some View {
        HStack {
            // Alarm status
            Button(action: { showAlarmSettings = true }) {
                HStack(spacing: 8) {
                    Image(systemName: alarmManager.alarmEnabled ? "alarm.fill" : "alarm")
                        .font(.system(size: 16))
                        .foregroundColor(alarmManager.alarmEnabled ? Theme.Colors.whoopTeal : Theme.Colors.textSecondary)

                    if alarmManager.alarmEnabled {
                        Text("ALARM ON \(alarmManager.alarmTimeFormatted)")
                            .font(Theme.Fonts.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.Colors.textPrimary)
                    } else {
                        Text("NO ALARM SET")
                            .font(Theme.Fonts.caption)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            // Divider
            Rectangle()
                .fill(Theme.Colors.borderSubtle)
                .frame(width: 1, height: 20)

            Spacer()

            // Plan Bedtime CTA
            Button(action: { showAlarmSettings = true }) {
                HStack(spacing: 4) {
                    Text("PLAN BEDTIME")
                        .font(Theme.Fonts.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.whoopTeal)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.whoopTeal)
                }
            }
        }
        .padding(.horizontal, Theme.Dimensions.cardPadding)
        .padding(.vertical, 12)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cardCornerRadius))
        .sheet(isPresented: $showAlarmSettings) {
            AlarmSettingsView()
        }
    }
}

/// Legacy initializer support for backwards compatibility
extension AlarmBedtimeRow {
    init(alarmEnabled: Bool, alarmTime: String?, onPlanBedtime: (() -> Void)? = nil) {
        // This initializer is kept for backwards compatibility
        // The view now uses AlarmManager directly
    }
}

#Preview {
    VStack(spacing: 16) {
        AlarmBedtimeRow()
    }
    .padding()
    .background(Theme.Colors.primary)
}
