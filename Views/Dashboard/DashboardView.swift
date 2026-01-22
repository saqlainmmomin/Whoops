import SwiftUI

// MARK: - Premium Quantified Self Dashboard
// Evolved from brutalist foundation with gradient themes

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: DashboardViewModel

    init() {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(healthKitManager: HealthKitManager()))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Void background
                Theme.Colors.void.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    headerSection

                    // Tabbed content
                    DashboardTabView(viewModel: viewModel)
                }
            }
            .navigationDestination(for: MetricType.self) { metricType in
                MetricDetailView(
                    metricType: metricType,
                    dailyMetrics: viewModel.todayMetrics,
                    baseline: viewModel.sevenDayBaseline,
                    historicalMetrics: viewModel.weeklyMetrics
                )
            }
            .toolbarBackground(Theme.Colors.void, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task {
            viewModel.setModelContext(modelContext)
            await viewModel.loadTodayData()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TODAY")
                    .font(Theme.Fonts.header(28))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(formattedDate)
                    .font(Theme.Fonts.mono(11))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .tracking(2)
            }

            Spacer()

            if viewModel.isLoading {
                ProgressView()
                    .tint(Theme.Colors.textSecondary)
            }

            // Settings gear
            NavigationLink(destination: Text("Settings")) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.md)
        .background(Theme.Colors.surface)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d"
        return formatter.string(from: Date()).uppercased()
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
        .environmentObject(HealthKitManager())
}
