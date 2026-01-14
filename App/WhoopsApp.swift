import SwiftUI
import SwiftData

@main
struct WhoopsApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var healthKitManager = HealthKitManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DailyMetricsRecord.self,
            BaselineRecord.self,
            UserProfile.self,
            Goal.self,
            DetectedPattern.self,
            WeeklyReport.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(healthKitManager)
                .modelContainer(sharedModelContainer)
                .preferredColorScheme(.dark) // Force Sovereign Dark Mode
                .task {
                    await healthKitManager.requestAuthorization()
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var appState: AppState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else {
                switch healthKitManager.authorizationStatus {
                case .notDetermined:
                    AuthorizationView()
                case .authorized:
                    MainTabView()
                case .denied:
                    PermissionDeniedView()
                }
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "circle.hexagonpath")
                    Text("Dashboard")
                }

            TimelineView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Timeline")
                }

            HabitsView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Habits")
                }

            ProfileTensorView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
        }
        .accentColor(Theme.Colors.neonTeal)
    }
}

struct AuthorizationView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)

            Text("Whoops")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Apple Health Analytics")
                .font(.title3)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                PermissionRow(icon: "heart.fill", text: "Heart Rate & HRV")
                PermissionRow(icon: "bed.double.fill", text: "Sleep Analysis")
                PermissionRow(icon: "figure.run", text: "Workouts & Activity")
                PermissionRow(icon: "flame.fill", text: "Energy Burned")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            Button {
                Task {
                    await healthKitManager.requestAuthorization()
                }
            } label: {
                Text("Connect Apple Health")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.top)

            Text("All data stays on your device")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(32)
    }
}

struct PermissionRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.red)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Health Access Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Whoops needs access to Apple Health to calculate your metrics. Please enable access in Settings.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding(32)
    }
}
