import SwiftUI

// MARK: - Brutalist Dashboard
// Hierarchy. Structure. Raw data.

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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // ZONE 1: Header
                        headerSection

                        // Hard divider
                        divider

                        // ZONE 2: Primary Metric (Recovery) - 40%+ visual weight
                        primaryMetricSection
                            .padding(.vertical, Theme.Spacing.lg)

                        // Hard divider
                        divider

                        // ZONE 3: Secondary Data Row (Strain + HRV + RHR)
                        secondaryDataSection
                            .padding(.vertical, Theme.Spacing.md)

                        // Hard divider
                        divider

                        // ZONE 4: Tertiary Data (Sleep + Activity)
                        tertiaryDataSection
                            .padding(.vertical, Theme.Spacing.md)

                        // Hard divider
                        divider

                        // ZONE 5: Status / Insight
                        insightSection
                            .padding(.vertical, Theme.Spacing.md)

                        Spacer(minLength: 100)
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
                    .font(Theme.Fonts.header(size: 28))
                    .foregroundColor(Theme.Colors.bone)

                Text(formattedDate)
                    .font(Theme.Fonts.mono(size: 11))
                    .foregroundColor(Theme.Colors.chalk)
                    .tracking(2)
            }

            Spacer()

            // Settings gear - industrial, not a bell
            NavigationLink(destination: Text("Settings")) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.Colors.chalk)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.lg)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d"
        return formatter.string(from: Date()).uppercased()
    }

    // MARK: - Primary Metric (Recovery)

    private var primaryMetricSection: some View {
        NavigationLink(value: MetricType.recovery) {
            SovereignGauge(
                score: viewModel.todayMetrics?.recoveryScore?.score ?? 0,
                type: .recovery,
                size: 80
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Secondary Data Row

    private var secondaryDataSection: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Strain - compact meter
            NavigationLink(value: MetricType.strain) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("STRAIN")
                        .font(Theme.Fonts.label(size: 9))
                        .foregroundColor(Theme.Colors.chalk)
                        .tracking(2)

                    HStack(spacing: Theme.Spacing.sm) {
                        strainBar
                        Text("\(viewModel.todayMetrics?.strainScore?.score ?? 0)")
                            .font(Theme.Fonts.mono(size: 24))
                            .foregroundColor(strainColor)
                            .monospacedDigit()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.concrete)
                .brutalistBorder()
            }
            .buttonStyle(PlainButtonStyle())

            // HRV
            NavigationLink(value: MetricType.hrv) {
                BrutalistDataCell(
                    label: "HRV",
                    value: "\(Int(viewModel.todayMetrics?.hrv?.nightlySDNN ?? viewModel.todayMetrics?.hrv?.averageSDNN ?? 0))",
                    unit: "ms"
                )
            }
            .buttonStyle(PlainButtonStyle())

            // RHR
            NavigationLink(value: MetricType.heartRate) {
                BrutalistDataCell(
                    label: "RHR",
                    value: "\(Int(viewModel.todayMetrics?.heartRate?.restingBPM ?? 0))",
                    unit: "bpm"
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    private var strainBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Theme.Colors.steel)
                Rectangle()
                    .fill(strainColor)
                    .frame(width: geo.size.width * CGFloat(viewModel.todayMetrics?.strainScore?.score ?? 0) / 100)
            }
        }
        .frame(width: 60, height: 8)
    }

    private var strainColor: Color {
        let score = viewModel.todayMetrics?.strainScore?.score ?? 0
        return score >= 67 ? Theme.Colors.rust : Theme.Colors.bone
    }

    // MARK: - Tertiary Data (Sleep + Activity)

    private var tertiaryDataSection: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Sleep - larger card
            NavigationLink(value: MetricType.sleep) {
                DeepDataCard(
                    title: "Sleep",
                    value: formatSleepDuration(viewModel.todayMetrics?.sleep?.totalSleepHours ?? 0),
                    subtitle: nil,
                    trend: viewModel.sleepTrend
                ) {
                    SparklineChart(
                        dataPoints: viewModel.sleepSparklineData,
                        color: Theme.Colors.bone,
                        height: 20
                    )
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Activity / Calories
            NavigationLink(value: MetricType.activity) {
                DeepDataCard(
                    title: "Active Cal",
                    value: "\(Int(viewModel.todayMetrics?.activity?.activeEnergy ?? 0))",
                    subtitle: "kcal",
                    trend: nil
                ) {
                    SparklineChart(
                        dataPoints: viewModel.activitySparklineData,
                        color: Theme.Colors.chalk,
                        height: 20
                    )
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    private func formatSleepDuration(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)H \(m)M"
    }

    // MARK: - Insight Section

    private var insightSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("STATUS")
                .font(Theme.Fonts.label(size: 10))
                .foregroundColor(Theme.Colors.chalk)
                .tracking(2)

            Rectangle()
                .fill(Theme.Colors.graphite)
                .frame(height: 1)

            Text(viewModel.todayMetrics?.recoveryScore?.category.description ?? "AWAITING DATA")
                .font(Theme.Fonts.mono(size: 14))
                .foregroundColor(Theme.Colors.bone)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.concrete)
        .brutalistBorder()
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(Theme.Colors.graphite)
            .frame(height: 1)
            .padding(.horizontal, Theme.Spacing.md)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
        .environmentObject(HealthKitManager())
}
