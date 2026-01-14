import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: DashboardViewModel

    init() {
        // Temporary init - will be replaced in .task
        _viewModel = StateObject(wrappedValue: DashboardViewModel(healthKitManager: HealthKitManager()))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Sovereign Black Background
                Theme.Colors.sovereignBlack.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {

                        // 2. Header
                        HStack {
                            Text("TODAY")
                                .font(Theme.Fonts.header(size: 32))
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "bell.badge")
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        // 3. Hero Section: Dual Gauges (Tappable)
                        HStack(spacing: 20) {
                            // Recovery (Hero)
                            NavigationLink(value: MetricType.recovery) {
                                SovereignGauge(
                                    score: viewModel.todayMetrics?.recoveryScore?.score ?? 0,
                                    type: .recovery,
                                    size: 180
                                )
                            }
                            .buttonStyle(PlainButtonStyle())

                            // Strain (Secondary)
                            NavigationLink(value: MetricType.strain) {
                                SovereignGauge(
                                    score: viewModel.todayMetrics?.strainScore?.score ?? 0,
                                    type: .strain,
                                    size: 120
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        // 4. Deep Data Grid (Tappable Cards with Sparklines)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {

                            NavigationLink(value: MetricType.hrv) {
                                DeepDataCard(
                                    title: "HRV",
                                    value: "\(Int(viewModel.todayMetrics?.hrv?.nightlySDNN ?? viewModel.todayMetrics?.hrv?.averageSDNN ?? 0))",
                                    subtitle: "ms",
                                    accent: Theme.Colors.neonTeal,
                                    trend: viewModel.hrvTrend
                                ) {
                                    SparklineChart(
                                        dataPoints: viewModel.hrvSparklineData,
                                        color: Theme.Colors.neonTeal,
                                        height: 24
                                    )
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                            NavigationLink(value: MetricType.heartRate) {
                                DeepDataCard(
                                    title: "RHR",
                                    value: "\(Int(viewModel.todayMetrics?.heartRate?.restingBPM ?? 0))",
                                    subtitle: "bpm",
                                    accent: Theme.Colors.neonRed,
                                    trend: viewModel.rhrTrend
                                ) {
                                    SparklineChart(
                                        dataPoints: viewModel.rhrSparklineData,
                                        color: Theme.Colors.neonRed,
                                        height: 24
                                    )
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                            NavigationLink(value: MetricType.sleep) {
                                DeepDataCard(
                                    title: "Sleep",
                                    value: String(format: "%.1f", viewModel.todayMetrics?.sleep?.totalSleepHours ?? 0),
                                    subtitle: "hrs",
                                    accent: Theme.Colors.neonGreen,
                                    trend: viewModel.sleepTrend
                                ) {
                                    SparklineChart(
                                        dataPoints: viewModel.sleepSparklineData,
                                        color: Theme.Colors.neonGreen,
                                        height: 24
                                    )
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                            NavigationLink(value: MetricType.activity) {
                                DeepDataCard(
                                    title: "Calories",
                                    value: "\(Int(viewModel.todayMetrics?.activity?.activeEnergy ?? 0))",
                                    subtitle: "kcal",
                                    accent: Theme.Colors.neonGold,
                                    trend: nil
                                ) {
                                    SparklineChart(
                                        dataPoints: viewModel.activitySparklineData,
                                        color: Theme.Colors.neonGold,
                                        height: 24
                                    )
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)

                        // 5. Context / Insight
                        VStack(alignment: .leading, spacing: 10) {
                            Text("INSIGHT")
                                .font(Theme.Fonts.label(size: 12))
                                .foregroundColor(Theme.Colors.textGray)
                                .tracking(1)

                            Text(viewModel.todayMetrics?.recoveryScore?.category.description ?? "Gathering enough data to provide insights...")
                                .font(Theme.Fonts.tensor(size: 16))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Theme.Colors.panelGray)
                        .cornerRadius(12)
                        .padding(.horizontal)

                        Spacer(minLength: 50)
                    }
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
            .toolbarBackground(Theme.Colors.sovereignBlack, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task {
            viewModel.setModelContext(modelContext)
            await viewModel.loadTodayData()
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
        .environmentObject(HealthKitManager())
}
