import SwiftUI

enum DashboardTab: String, CaseIterable {
    case overview = "OVERVIEW"
    case sleep = "SLEEP"
    case recovery = "RECOVERY"
    case strain = "STRAIN"
}

struct DashboardTabView: View {
    @State private var selectedTab: DashboardTab = .overview
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                ForEach(DashboardTab.allCases, id: \.self) { tab in
                    TabButton(title: tab.rawValue, isSelected: selectedTab == tab) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Colors.surface)

            Divider().background(Theme.Colors.borderSubtle)

            TabView(selection: $selectedTab) {
                OverviewTab(viewModel: viewModel).tag(DashboardTab.overview)
                SleepTab(viewModel: viewModel).tag(DashboardTab.sleep)
                RecoveryTab(viewModel: viewModel).tag(DashboardTab.recovery)
                StrainTab(viewModel: viewModel).tag(DashboardTab.strain)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Theme.Colors.void)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(title)
                    .font(Theme.Fonts.label(11))
                    .tracking(1)
                    .foregroundStyle(isSelected ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)

                Rectangle()
                    .fill(isSelected ? Theme.Colors.textPrimary : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    DashboardTabView(viewModel: DashboardViewModel(healthKitManager: HealthKitManager()))
        .preferredColorScheme(.dark)
}
