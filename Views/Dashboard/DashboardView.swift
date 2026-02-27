import SwiftUI

// MARK: - Premium Quantified Self Dashboard
// Evolved from brutalist foundation with gradient themes

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: DashboardViewModel

    init(healthKitManager: HealthKitManager) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(healthKitManager: healthKitManager))
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

    // MARK: - Header Section (Whoop-style)

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 0) {
            // Profile avatar (left)
            Circle()
                .fill(Theme.Colors.whoopTeal.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.whoopTeal)
                )

            Spacer()

            // TODAY navigation (center)
            HStack(spacing: 12) {
                Button(action: { /* TODO: Previous day */ }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                }

                Text("TODAY")
                    .font(Theme.Fonts.header(16))
                    .foregroundColor(Theme.Colors.textPrimary)

                Button(action: { /* TODO: Next day */ }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
                }
            }

            Spacer()

            // Battery/device indicator (right)
            HStack(spacing: 4) {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(Theme.Colors.textSecondary)
                } else {
                    Text("53%")
                        .font(Theme.Fonts.mono(12))
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                Image(systemName: "battery.75")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.whoopTeal)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, 12)
        .background(Theme.Colors.surface)
    }
}

#Preview {
    DashboardView(healthKitManager: HealthKitManager())
        .environmentObject(AppState())
        .environmentObject(HealthKitManager())
}
