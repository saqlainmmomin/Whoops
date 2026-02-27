import SwiftUI

/// Alarm and bedtime settings view
/// Allows users to configure wake-up and bedtime preferences
struct AlarmSettingsView: View {
    @StateObject private var alarmManager = AlarmManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedAlarmTime: Date
    @State private var selectedBedtime: Date
    @State private var showingAlarmPicker = false
    @State private var showingBedtimePicker = false

    init() {
        let manager = AlarmManager.shared
        _selectedAlarmTime = State(initialValue: manager.alarmDate)
        _selectedBedtime = State(initialValue: manager.bedtimeDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.moduleP) {
                    // Alarm Section
                    alarmSection
                        .padding(.horizontal, Theme.Spacing.moduleP)

                    // Bedtime Section
                    bedtimeSection
                        .padding(.horizontal, Theme.Spacing.moduleP)

                    // Open Clock App Button
                    openClockButton
                        .padding(.horizontal, Theme.Spacing.moduleP)

                    // Info Card
                    infoCard
                        .padding(.horizontal, Theme.Spacing.moduleP)
                }
                .padding(.vertical, Theme.Spacing.moduleP)
            }
            .background(Theme.Colors.primary)
            .navigationTitle("Alarm & Bedtime")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.Colors.whoopTeal)
                }
            }
        }
    }

    // MARK: - Alarm Section

    private var alarmSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ALARM")
                .whoopSectionHeader()

            VStack(spacing: 0) {
                // Enable/Disable Toggle
                HStack {
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 20))
                        .foregroundColor(alarmManager.alarmEnabled ? Theme.Colors.whoopTeal : Theme.Colors.textSecondary)

                    Text("Smart Wake Notification")
                        .font(Theme.Fonts.body)
                        .foregroundColor(Theme.Colors.textPrimary)

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { alarmManager.alarmEnabled },
                        set: { alarmManager.toggleAlarm($0) }
                    ))
                    .tint(Theme.Colors.whoopTeal)
                }
                .padding(Theme.Dimensions.cardPadding)

                if alarmManager.alarmEnabled {
                    Divider()
                        .background(Theme.Colors.borderSubtle)

                    // Time Picker
                    Button(action: { showingAlarmPicker.toggle() }) {
                        HStack {
                            Text("Wake Time")
                                .font(Theme.Fonts.body)
                                .foregroundColor(Theme.Colors.textPrimary)

                            Spacer()

                            Text(alarmManager.alarmTimeFormatted)
                                .font(Theme.Fonts.mediumValue)
                                .foregroundColor(Theme.Colors.whoopTeal)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.Colors.textTertiary)
                        }
                        .padding(Theme.Dimensions.cardPadding)
                    }

                    if showingAlarmPicker {
                        DatePicker(
                            "",
                            selection: $selectedAlarmTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .onChange(of: selectedAlarmTime) { _, newValue in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                            alarmManager.setAlarm(hour: components.hour ?? 7, minute: components.minute ?? 0)
                        }
                        .padding(.horizontal, Theme.Dimensions.cardPadding)
                        .padding(.bottom, Theme.Dimensions.cardPadding)
                    }
                }
            }
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cardCornerRadius))
        }
    }

    // MARK: - Bedtime Section

    private var bedtimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BEDTIME")
                .whoopSectionHeader()

            VStack(spacing: 0) {
                // Enable/Disable Toggle
                HStack {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 20))
                        .foregroundColor(alarmManager.bedtimeEnabled ? Theme.Colors.stageDeep : Theme.Colors.textSecondary)

                    Text("Bedtime Reminder")
                        .font(Theme.Fonts.body)
                        .foregroundColor(Theme.Colors.textPrimary)

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { alarmManager.bedtimeEnabled },
                        set: { alarmManager.toggleBedtime($0) }
                    ))
                    .tint(Theme.Colors.whoopTeal)
                }
                .padding(Theme.Dimensions.cardPadding)

                if alarmManager.bedtimeEnabled {
                    Divider()
                        .background(Theme.Colors.borderSubtle)

                    // Time Picker
                    Button(action: { showingBedtimePicker.toggle() }) {
                        HStack {
                            Text("Bedtime")
                                .font(Theme.Fonts.body)
                                .foregroundColor(Theme.Colors.textPrimary)

                            Spacer()

                            Text(alarmManager.bedtimeFormatted)
                                .font(Theme.Fonts.mediumValue)
                                .foregroundColor(Theme.Colors.stageDeep)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.Colors.textTertiary)
                        }
                        .padding(Theme.Dimensions.cardPadding)
                    }

                    if showingBedtimePicker {
                        DatePicker(
                            "",
                            selection: $selectedBedtime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .onChange(of: selectedBedtime) { _, newValue in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                            alarmManager.setBedtime(hour: components.hour ?? 22, minute: components.minute ?? 30)
                        }
                        .padding(.horizontal, Theme.Dimensions.cardPadding)
                        .padding(.bottom, Theme.Dimensions.cardPadding)
                    }

                    Divider()
                        .background(Theme.Colors.borderSubtle)

                    // Reminder Time
                    HStack {
                        Text("Remind me")
                            .font(Theme.Fonts.body)
                            .foregroundColor(Theme.Colors.textPrimary)

                        Spacer()

                        Picker("", selection: Binding(
                            get: { alarmManager.reminderMinutesBefore },
                            set: { alarmManager.reminderMinutesBefore = $0 }
                        )) {
                            Text("15 min before").tag(15)
                            Text("30 min before").tag(30)
                            Text("45 min before").tag(45)
                            Text("1 hour before").tag(60)
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.Colors.whoopTeal)
                    }
                    .padding(Theme.Dimensions.cardPadding)
                }
            }
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cardCornerRadius))
        }
    }

    // MARK: - Open Clock App Button

    private var openClockButton: some View {
        Button(action: { alarmManager.openClockApp() }) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.Colors.whoopCyan)

                Text("Open Clock App for Native Alarm")
                    .font(Theme.Fonts.body)
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.textTertiary)
            }
            .padding(Theme.Dimensions.cardPadding)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cardCornerRadius))
        }
        .buttonStyle(WhoopCardButtonStyle())
    }

    // MARK: - Info Card

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.whoopTeal)

                Text("About Smart Wake")
                    .font(Theme.Fonts.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.textPrimary)
            }

            Text("Smart Wake sends a notification at your set time. For a full alarm experience with sound that persists until dismissed, use the native Clock app.")
                .font(Theme.Fonts.footnote)
                .foregroundColor(Theme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Dimensions.cardPadding)
        .background(Theme.Colors.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cardCornerRadius))
    }
}

#Preview {
    AlarmSettingsView()
        .preferredColorScheme(.dark)
}
