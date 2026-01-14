import SwiftUI
import SwiftData

struct ProfileTensorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdDate, order: .reverse) private var profiles: [UserProfile]
    @Query(sort: \DailyMetricsRecord.date, order: .reverse) private var metricsRecords: [DailyMetricsRecord]

    @State private var isEditingName = false
    @State private var editedName = ""

    private var userProfile: UserProfile? {
        profiles.first
    }

    private var daysTracked: Int {
        metricsRecords.count
    }

    private var earliestDate: Date? {
        metricsRecords.last?.date
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.sovereignBlack.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header with name
                        headerSection

                        // Health characteristics from HealthKit
                        healthCharacteristicsSection

                        // Tracking stats
                        trackingStatsSection

                        // Settings
                        settingsSection

                        // App info
                        appInfoSection

                        Spacer(minLength: 50)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Theme.Colors.sovereignBlack, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PROFILE")
                .font(Theme.Fonts.label(size: 12))
                .foregroundColor(Theme.Colors.neonTeal)
                .tracking(1)

            if isEditingName {
                HStack {
                    TextField("Name", text: $editedName)
                        .font(Theme.Fonts.header(size: 28))
                        .foregroundColor(.white)
                        .textFieldStyle(.plain)

                    Button {
                        saveName()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.Colors.neonGreen)
                            .font(.system(size: 24))
                    }
                }
            } else {
                HStack {
                    Text(userProfile?.name ?? "User")
                        .font(Theme.Fonts.header(size: 28))
                        .foregroundColor(.white)

                    Button {
                        editedName = userProfile?.name ?? ""
                        isEditingName = true
                    } label: {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(Theme.Colors.textGray)
                            .font(.system(size: 20))
                    }
                }
            }

            if let createdDate = userProfile?.createdDate {
                Text("Member since \(createdDate.formatted(.dateTime.month().year()))")
                    .font(Theme.Fonts.tensor(size: 12))
                    .foregroundColor(Theme.Colors.textGray)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Health Characteristics Section

    private var healthCharacteristicsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("HEALTH DATA")

            VStack(spacing: 12) {
                if let age = userProfile?.age {
                    characteristicRow(icon: "calendar", label: "Age", value: "\(age) years", color: Theme.Colors.neonTeal)
                }

                if let sex = userProfile?.biologicalSex {
                    characteristicRow(icon: "person.fill", label: "Sex", value: sex, color: Theme.Colors.neonTeal)
                }

                if let height = userProfile?.displayHeight {
                    characteristicRow(icon: "ruler", label: "Height", value: height, color: Theme.Colors.neonGreen)
                }

                if let weight = userProfile?.displayWeight {
                    characteristicRow(icon: "scalemass", label: "Weight", value: weight, color: Theme.Colors.neonGreen)
                }

                if let maxHR = userProfile?.estimatedMaxHR {
                    characteristicRow(icon: "heart.fill", label: "Est. Max HR", value: "\(maxHR) bpm", color: Theme.Colors.neonRed)
                }

                if userProfile?.age == nil && userProfile?.heightCM == nil {
                    VStack(spacing: 8) {
                        Image(systemName: "heart.text.square")
                            .font(.system(size: 30))
                            .foregroundColor(Theme.Colors.textGray)

                        Text("Health characteristics will appear here once synced from Apple Health")
                            .font(Theme.Fonts.tensor(size: 12))
                            .foregroundColor(Theme.Colors.textGray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .padding()
            .background(Theme.Colors.panelGray)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    private func characteristicRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(label)
                .font(Theme.Fonts.tensor(size: 14))
                .foregroundColor(Theme.Colors.textGray)

            Spacer()

            Text(value)
                .font(Theme.Fonts.tensor(size: 14))
                .foregroundColor(.white)
        }
    }

    // MARK: - Tracking Stats Section

    private var trackingStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("TRACKING STATS")

            HStack(spacing: 16) {
                statBox(label: "Days Tracked", value: "\(daysTracked)", accent: Theme.Colors.neonTeal)

                if let earliest = earliestDate {
                    statBox(label: "Since", value: earliest.formatted(.dateTime.month(.abbreviated).day()), accent: Theme.Colors.neonGreen)
                }
            }
        }
        .padding(.horizontal)
    }

    private func statBox(label: String, value: String, accent: Color) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(Theme.Fonts.label(size: 10))
                .foregroundColor(Theme.Colors.textGray)

            Text(value)
                .font(Theme.Fonts.tensor(size: 20))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.Colors.panelGray)
        .cornerRadius(12)
        .overlay(
            Rectangle()
                .fill(accent)
                .frame(height: 2),
            alignment: .top
        )
    }

    // MARK: - Settings Section

    @State private var showingNotificationSettings = false

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("SETTINGS")

            VStack(spacing: 0) {
                Button {
                    showingNotificationSettings = true
                } label: {
                    HStack {
                        Image(systemName: "bell.badge")
                            .foregroundColor(Theme.Colors.neonTeal)
                            .frame(width: 24)

                        Text("Notifications")
                            .font(Theme.Fonts.tensor(size: 14))
                            .foregroundColor(.white)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(Theme.Colors.textGray)
                            .font(.system(size: 12))
                    }
                    .padding()
                }
            }
            .background(Theme.Colors.panelGray)
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("APP INFO")

            VStack(spacing: 0) {
                infoRow(icon: "lock.shield", label: "Privacy", detail: "All data stays on device")
                Divider().background(Theme.Colors.textGray.opacity(0.3))
                infoRow(icon: "arrow.down.heart", label: "Data Source", detail: "Apple Health")
                Divider().background(Theme.Colors.textGray.opacity(0.3))
                infoRow(icon: "info.circle", label: "Version", detail: "1.0.0")
            }
            .padding()
            .background(Theme.Colors.panelGray)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    private func infoRow(icon: String, label: String, detail: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Theme.Colors.textGray)
                .frame(width: 24)

            Text(label)
                .font(Theme.Fonts.tensor(size: 14))
                .foregroundColor(.white)

            Spacer()

            Text(detail)
                .font(Theme.Fonts.tensor(size: 12))
                .foregroundColor(Theme.Colors.textGray)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Theme.Fonts.label(size: 12))
            .foregroundColor(Theme.Colors.textGray)
            .tracking(1)
    }

    private func saveName() {
        if let profile = userProfile {
            profile.name = editedName.trimmingCharacters(in: .whitespaces)
            try? modelContext.save()
        }
        isEditingName = false
    }
}

// Helper Slider Component
struct TensorSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let accent: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label)
                    .font(Theme.Fonts.tensor(size: 12))
                    .foregroundColor(Theme.Colors.textGray)
                Spacer()
                Text(String(format: "%.1f", value))
                    .font(Theme.Fonts.tensor(size: 16))
                    .foregroundColor(accent)
            }
            
            Slider(value: $value, in: range)
                .tint(accent)
        }
    }
}

#Preview {
    ProfileTensorView()
}
