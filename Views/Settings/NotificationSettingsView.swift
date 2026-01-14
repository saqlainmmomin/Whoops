import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingTimePicker = false
    @State private var selectedTime = Date()

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.sovereignBlack.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Authorization status
                        authorizationSection

                        // Notification types
                        if notificationManager.isAuthorized {
                            notificationTypesSection
                        }

                        Spacer(minLength: 50)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Theme.Colors.sovereignBlack, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.Colors.neonTeal)
                }
            }
            .sheet(isPresented: $showingTimePicker) {
                bedtimePickerSheet
            }
            .onAppear {
                // Set initial time from stored values
                var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                components.hour = notificationManager.bedtimeHour
                components.minute = notificationManager.bedtimeMinute
                selectedTime = Calendar.current.date(from: components) ?? Date()
            }
        }
    }

    // MARK: - Authorization Section

    private var authorizationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("STATUS")

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: notificationManager.isAuthorized ? "bell.badge.fill" : "bell.slash.fill")
                        .foregroundColor(notificationManager.isAuthorized ? Theme.Colors.neonGreen : Theme.Colors.neonRed)
                        .frame(width: 24)

                    Text("Notifications")
                        .font(Theme.Fonts.tensor(size: 14))
                        .foregroundColor(.white)

                    Spacer()

                    if notificationManager.isAuthorized {
                        Text("Enabled")
                            .font(Theme.Fonts.label(size: 12))
                            .foregroundColor(Theme.Colors.neonGreen)
                    } else {
                        Button("Enable") {
                            Task {
                                await notificationManager.requestAuthorization()
                            }
                        }
                        .font(Theme.Fonts.tensor(size: 14))
                        .foregroundColor(Theme.Colors.neonTeal)
                    }
                }
                .padding()

                if !notificationManager.isAuthorized {
                    Divider().background(Theme.Colors.textGray.opacity(0.3))

                    HStack {
                        Text("Enable notifications to receive recovery alerts, bedtime reminders, and weekly summaries.")
                            .font(Theme.Fonts.tensor(size: 12))
                            .foregroundColor(Theme.Colors.textGray)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                }
            }
            .background(Theme.Colors.panelGray)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    // MARK: - Notification Types Section

    private var notificationTypesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("NOTIFICATION TYPES")

            VStack(spacing: 0) {
                // Low Recovery Alert
                notificationToggle(
                    icon: "arrow.down.heart.fill",
                    iconColor: Theme.Colors.neonRed,
                    title: "Low Recovery Alert",
                    description: "Get notified when your recovery drops below 33%",
                    isOn: Binding(
                        get: { notificationManager.lowRecoveryAlertEnabled },
                        set: { notificationManager.toggleLowRecoveryAlert($0) }
                    )
                )

                Divider().background(Theme.Colors.textGray.opacity(0.3))

                // Bedtime Reminder
                VStack(spacing: 0) {
                    notificationToggle(
                        icon: "bed.double.fill",
                        iconColor: .purple,
                        title: "Bedtime Reminder",
                        description: "Reminder 30 minutes before your target bedtime",
                        isOn: Binding(
                            get: { notificationManager.bedtimeReminderEnabled },
                            set: { notificationManager.toggleBedtimeReminder($0) }
                        )
                    )

                    if notificationManager.bedtimeReminderEnabled {
                        HStack {
                            Text("Target Bedtime")
                                .font(Theme.Fonts.tensor(size: 12))
                                .foregroundColor(Theme.Colors.textGray)

                            Spacer()

                            Button {
                                showingTimePicker = true
                            } label: {
                                Text(formattedBedtime)
                                    .font(Theme.Fonts.tensor(size: 14))
                                    .foregroundColor(Theme.Colors.neonTeal)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    }
                }

                Divider().background(Theme.Colors.textGray.opacity(0.3))

                // Weekly Digest
                notificationToggle(
                    icon: "chart.bar.doc.horizontal.fill",
                    iconColor: Theme.Colors.neonGold,
                    title: "Weekly Summary",
                    description: "Receive your weekly health report every Sunday",
                    isOn: Binding(
                        get: { notificationManager.weeklyDigestEnabled },
                        set: { notificationManager.toggleWeeklyDigest($0) }
                    )
                )
            }
            .background(Theme.Colors.panelGray)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    // MARK: - Bedtime Picker Sheet

    private var bedtimePickerSheet: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.sovereignBlack.ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Select Your Target Bedtime")
                        .font(Theme.Fonts.header(size: 18))
                        .foregroundColor(.white)

                    DatePicker(
                        "Bedtime",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)

                    Text("You'll receive a reminder 30 minutes before this time")
                        .font(Theme.Fonts.tensor(size: 12))
                        .foregroundColor(Theme.Colors.textGray)
                        .multilineTextAlignment(.center)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Bedtime")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.sovereignBlack, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingTimePicker = false
                    }
                    .foregroundColor(Theme.Colors.textGray)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                        notificationManager.updateBedtimeReminder(
                            hour: components.hour ?? 22,
                            minute: components.minute ?? 30
                        )
                        showingTimePicker = false
                    }
                    .foregroundColor(Theme.Colors.neonTeal)
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Theme.Fonts.label(size: 12))
            .foregroundColor(Theme.Colors.textGray)
            .tracking(1)
    }

    private func notificationToggle(icon: String, iconColor: Color, title: String, description: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.Fonts.tensor(size: 14))
                    .foregroundColor(.white)

                Text(description)
                    .font(Theme.Fonts.tensor(size: 12))
                    .foregroundColor(Theme.Colors.textGray)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Theme.Colors.neonTeal)
        }
        .padding()
    }

    private var formattedBedtime: String {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = notificationManager.bedtimeHour
        components.minute = notificationManager.bedtimeMinute

        if let date = Calendar.current.date(from: components) {
            return date.formatted(date: .omitted, time: .shortened)
        }
        return "\(notificationManager.bedtimeHour):\(String(format: "%02d", notificationManager.bedtimeMinute))"
    }
}

#Preview {
    NotificationSettingsView()
}
