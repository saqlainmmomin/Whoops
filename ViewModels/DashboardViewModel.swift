import Foundation
import SwiftUI
import Combine
import SwiftData

@MainActor
class DashboardViewModel: ObservableObject {
    private let healthKitManager: HealthKitManager
    private var modelContext: ModelContext?

    @Published var isLoading = false
    @Published var errorMessage: String?

    // Today's metrics
    @Published var todayMetrics: DailyMetrics?
    @Published var recoveryScore: RecoveryScore?
    @Published var strainScore: StrainScore?
    @Published var sleepSummary: DailySleepSummary?

    // Baselines
    @Published var sevenDayBaseline: Baseline?
    @Published var twentyEightDayBaseline: Baseline?

    // Historical data for context
    @Published var weeklyMetrics: [DailyMetrics] = []
    @Published var weeklyRecoveryScores: [Int] = []
    @Published var weeklyStrainScores: [Int] = []

    // Trends
    @Published var recoveryTrend: TrendDirection?
    @Published var strainTrend: TrendDirection?
    @Published var hrvTrend: TrendDirection?
    @Published var rhrTrend: TrendDirection?
    @Published var sleepTrend: TrendDirection?

    init(healthKitManager: HealthKitManager) {
        self.healthKitManager = healthKitManager
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Data Loading

    func loadTodayData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch raw data from HealthKit
            let rawData = try await healthKitManager.fetchDailyData(for: Date())

            // Fetch historical data for baseline
            let last28Days = DateHelpers.datesInLast(days: 28, from: Date().adding(days: -1))
            var historicalMetrics: [DailyMetrics] = []

            for date in last28Days {
                if let cached = await loadCachedMetrics(for: date) {
                    historicalMetrics.append(cached)
                } else {
                    // Fetch and cache
                    let dailyRaw = try await healthKitManager.fetchDailyData(for: date)
                    let metrics = processRawData(dailyRaw, historicalMetrics: historicalMetrics)
                    historicalMetrics.append(metrics)
                    await cacheMetrics(metrics)
                }
            }

            // Calculate baselines
            let baselines = BaselineEngine.calculateBaselines(from: historicalMetrics, asOf: Date())
            sevenDayBaseline = baselines.sevenDay
            twentyEightDayBaseline = baselines.twentyEightDay

            // Process today's data
            var metrics = processRawData(rawData, historicalMetrics: historicalMetrics)

            // Calculate Tier 2 metrics
            Tier2Calculator.calculateTier2Metrics(
                for: &metrics,
                historicalMetrics: historicalMetrics,
                baseline7Day: baselines.sevenDay,
                baseline28Day: baselines.twentyEightDay
            )

            // Calculate inference scores
            metrics.recoveryScore = calculateRecoveryScore(for: metrics, baseline: baselines.sevenDay)
            metrics.strainScore = calculateStrainScore(for: metrics, baseline: baselines.sevenDay)

            // Update published properties
            todayMetrics = metrics
            recoveryScore = metrics.recoveryScore
            strainScore = metrics.strainScore
            sleepSummary = metrics.sleep

            // Calculate weekly data
            weeklyMetrics = Array(historicalMetrics.suffix(7)) + [metrics]
            weeklyRecoveryScores = weeklyMetrics.compactMap { $0.recoveryScore?.score }
            weeklyStrainScores = weeklyMetrics.compactMap { $0.strainScore?.score }

            // Calculate trends
            calculateTrends(from: weeklyMetrics)

        } catch {
            errorMessage = "Failed to load health data: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Data Processing

    private func processRawData(_ raw: RawDailyHealthData, historicalMetrics: [DailyMetrics]) -> DailyMetrics {
        let date = raw.date
        let sleepWindow = DateHelpers.sleepWindow(for: date)

        // Tier 1 calculations
        let heartRateSummary = Tier1Calculator.calculateHeartRateSummary(
            heartRateSamples: raw.heartRateSamples,
            restingHRSamples: raw.restingHeartRateSamples,
            for: date
        )

        let hrvSummary = Tier1Calculator.calculateHRVSummary(
            hrvSamples: raw.hrvSamples,
            sleepWindow: sleepWindow,
            for: date
        )

        let sleepSummary = Tier1Calculator.calculateSleepSummary(
            sleepSamples: raw.sleepSamples,
            for: date
        )

        let workoutSummary = Tier1Calculator.calculateWorkoutSummary(
            workouts: raw.workouts,
            for: date
        )

        let activitySummary = Tier1Calculator.calculateActivitySummary(
            steps: raw.steps,
            distance: raw.distance,
            activeEnergy: raw.activeEnergy,
            basalEnergy: raw.basalEnergy,
            for: date
        )

        let zoneDistribution = Tier1Calculator.calculateZoneDistribution(
            heartRateSamples: raw.heartRateSamples,
            maxHeartRate: Constants.HeartRateZones.defaultMaxHR
        )

        // HR Recovery (if workout today)
        var hrRecovery: HRRecoveryData?
        if let lastWorkout = raw.workouts.last {
            hrRecovery = Tier1Calculator.calculateHRRecovery(
                workout: lastWorkout,
                heartRateSamples: raw.heartRateSamples
            )
        }

        // Data quality
        let dataQuality = Tier1Calculator.assessDataQuality(
            heartRateSamples: raw.heartRateSamples,
            hrvSamples: raw.hrvSamples,
            sleepSummary: sleepSummary,
            activitySummary: activitySummary
        )

        return DailyMetrics(
            date: date,
            heartRate: heartRateSummary,
            hrv: hrvSummary,
            sleep: sleepSummary,
            workouts: workoutSummary,
            activity: activitySummary,
            zoneDistribution: zoneDistribution,
            hrRecovery: hrRecovery,
            acuteLoad: nil,
            chronicLoad: nil,
            loadRatio: nil,
            sleepDebt: nil,
            hrvDeviation: nil,
            rhrDeviation: nil,
            sleepTimingConsistency: nil,
            recoveryScore: nil,
            strainScore: nil,
            dataQuality: dataQuality
        )
    }

    // MARK: - Score Calculations

    private func calculateRecoveryScore(for metrics: DailyMetrics, baseline: Baseline) -> RecoveryScore? {
        let hrvDeviation = metrics.hrv.flatMap { hrv in
            baseline.hrvZScore(for: hrv.nightlySDNN ?? hrv.averageSDNN)
        }

        let rhrDeviation = metrics.heartRate?.restingBPM.flatMap { rhr in
            baseline.rhrDeviation(from: rhr)
        }

        let sleepRatio = metrics.sleep.flatMap { sleep in
            baseline.sleepDurationRatio(for: sleep.totalSleepHours)
        }

        let interruptions = metrics.sleep?.totalInterruptions

        return RecoveryScoreEngine.calculateRecoveryScore(
            hrvDeviation: hrvDeviation,
            rhrDeviation: rhrDeviation,
            sleepDurationRatio: sleepRatio,
            sleepInterruptions: interruptions,
            dataQuality: metrics.dataQuality
        )
    }

    private func calculateStrainScore(for metrics: DailyMetrics, baseline: Baseline) -> StrainScore {
        StrainScoreEngine.calculateStrainScore(
            zoneDistribution: metrics.zoneDistribution,
            workoutDurationMinutes: metrics.workouts?.totalDurationMinutes ?? 0,
            activeEnergy: metrics.activity?.activeEnergy ?? 0,
            baselineActiveEnergy: baseline.averageActiveEnergy,
            dataQuality: metrics.dataQuality
        )
    }

    // MARK: - Trends

    private func calculateTrends(from metrics: [DailyMetrics]) {
        // Recovery trend
        if let trend = BaselineEngine.calculateHRVTrend(from: metrics, windowDays: 7) {
            recoveryTrend = trend.direction
        }

        // Strain trend
        let strainScores = metrics.compactMap { $0.strainScore?.score }
        strainTrend = StrainScoreEngine.calculateStrainTrend(dailyStrainScores: strainScores)

        // HRV trend
        if let trend = BaselineEngine.calculateHRVTrend(from: metrics) {
            hrvTrend = trend.direction
        }

        // RHR trend (lower is better, so we invert the direction)
        let rhrValues = metrics.compactMap { $0.heartRate?.restingBPM }
        if rhrValues.count >= 3 {
            let recentAvg = rhrValues.suffix(3).reduce(0, +) / Double(min(3, rhrValues.count))
            let olderAvg = rhrValues.prefix(rhrValues.count - 3).reduce(0, +) / Double(max(1, rhrValues.count - 3))
            let diff = recentAvg - olderAvg
            if diff < -2 {
                rhrTrend = .improving // Lower RHR is better
            } else if diff > 2 {
                rhrTrend = .declining
            } else {
                rhrTrend = .stable
            }
        }

        // Sleep trend
        let sleepHours = metrics.compactMap { $0.sleep?.totalSleepHours }
        if sleepHours.count >= 3 {
            let recentAvg = sleepHours.suffix(3).reduce(0, +) / Double(min(3, sleepHours.count))
            let olderAvg = sleepHours.prefix(sleepHours.count - 3).reduce(0, +) / Double(max(1, sleepHours.count - 3))
            let diff = recentAvg - olderAvg
            if diff > 0.25 {
                sleepTrend = .improving
            } else if diff < -0.25 {
                sleepTrend = .declining
            } else {
                sleepTrend = .stable
            }
        }
    }

    // MARK: - Persistence

    private func loadCachedMetrics(for date: Date) async -> DailyMetrics? {
        guard let context = modelContext else { return nil }

        let startOfDay = DateHelpers.startOfDay(date)
        let predicate = #Predicate<DailyMetricsRecord> { record in
            record.date == startOfDay
        }

        let descriptor = FetchDescriptor<DailyMetricsRecord>(predicate: predicate)

        do {
            let records = try context.fetch(descriptor)
            return try records.first?.getMetrics()
        } catch {
            return nil
        }
    }

    private func cacheMetrics(_ metrics: DailyMetrics) async {
        guard let context = modelContext else { return }

        do {
            let record = try DailyMetricsRecord(date: metrics.date.startOfDay, metrics: metrics)
            context.insert(record)
            try context.save()
        } catch {
            print("Failed to cache metrics: \(error)")
        }
    }

    // MARK: - Helpers

    var formattedDate: String {
        DateHelpers.relativeDescription(Date())
    }

    var hasData: Bool {
        todayMetrics != nil
    }

    var dataQualityMessage: String? {
        guard let quality = todayMetrics?.dataQuality else { return nil }
        let gaps = quality.gapDescriptions
        return gaps.isEmpty ? nil : gaps.joined(separator: ". ")
    }

    // MARK: - Sparkline Data

    var hrvSparklineData: [Double] {
        weeklyMetrics.compactMap { $0.hrv?.nightlySDNN ?? $0.hrv?.averageSDNN }
    }

    var rhrSparklineData: [Double] {
        weeklyMetrics.compactMap { $0.heartRate?.restingBPM }
    }

    var sleepSparklineData: [Double] {
        weeklyMetrics.compactMap { $0.sleep?.totalSleepHours }
    }

    var activitySparklineData: [Double] {
        weeklyMetrics.compactMap { $0.activity?.activeEnergy }
    }

    var recoverySparklineData: [Double] {
        weeklyMetrics.compactMap { $0.recoveryScore?.score }.map { Double($0) }
    }

    var strainSparklineData: [Double] {
        weeklyMetrics.compactMap { $0.strainScore?.score }.map { Double($0) }
    }

    // MARK: - New Dashboard Properties

    /// Recovery category string (e.g., "Peak", "Good", "Moderate", "Low")
    var recoveryCategory: String {
        guard let score = todayMetrics?.recoveryScore?.score else { return "Unknown" }
        switch score {
        case 85...100: return "Peak"
        case 67..<85: return "Good"
        case 34..<67: return "Moderate"
        case 1..<34: return "Low"
        default: return "Critical"
        }
    }

    /// Weekly average recovery score
    var weeklyRecoveryAvg: Double? {
        let scores = weeklyRecoveryScores
        guard !scores.isEmpty else { return nil }
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }

    /// HRV deviation as percentage from baseline
    var hrvDeviationPercent: Double? {
        guard let hrv = todayMetrics?.hrv,
              let baseline = sevenDayBaseline,
              let avgHRV = baseline.averageHRV,
              avgHRV > 0 else { return nil }

        let hrvValue = hrv.nightlySDNN ?? hrv.averageSDNN
        return ((hrvValue - avgHRV) / avgHRV) * 100
    }

    /// RHR deviation as percentage from baseline
    var rhrDeviationPercent: Double? {
        guard let rhr = todayMetrics?.heartRate?.restingBPM,
              let baseline = sevenDayBaseline,
              let avgRHR = baseline.averageRestingHR,
              avgRHR > 0 else { return nil }

        return ((rhr - avgRHR) / avgRHR) * 100
    }

    /// Strain score normalized to 0-21 scale (Whoop-style)
    var strainScoreNormalized: Double {
        guard let score = todayMetrics?.strainScore?.score else { return 0 }
        // Convert 0-100 to 0-21 scale
        return Double(score) / 100.0 * 21.0
    }

    /// Optimal strain target based on recovery
    var optimalStrainTarget: Double? {
        guard let recovery = todayMetrics?.recoveryScore?.score else { return nil }
        // Higher recovery = higher strain capacity
        switch recovery {
        case 85...100: return 18.0
        case 67..<85: return 14.0
        case 34..<67: return 10.0
        default: return 6.0
        }
    }

    /// Weekly average strain on 0-21 scale
    var weeklyStrainAvg: Double? {
        let scores = weeklyStrainScores
        guard !scores.isEmpty else { return nil }
        let avgScore = Double(scores.reduce(0, +)) / Double(scores.count)
        return avgScore / 100.0 * 21.0
    }

    /// Primary insight for today
    var primaryInsight: Insight? {
        guard let metrics = todayMetrics else { return nil }
        return InsightGenerator.shared.getPrimaryInsight(metrics: metrics, baseline: sevenDayBaseline)
    }

    /// Health monitor result
    private var healthMonitorResult: HealthMonitorResult {
        guard let metrics = todayMetrics else {
            return HealthMonitorResult(metricsInRange: 0, totalMetrics: 5, flaggedMetrics: [])
        }

        if let baseline = sevenDayBaseline {
            return HealthMonitorEngine.shared.evaluate(metrics: metrics, baseline: baseline)
        } else {
            return HealthMonitorEngine.shared.evaluateWithDefaults(metrics: metrics)
        }
    }

    /// Number of metrics within healthy range
    var metricsInRange: Int {
        healthMonitorResult.metricsInRange
    }

    /// Total number of monitored metrics
    var totalMonitoredMetrics: Int {
        healthMonitorResult.totalMetrics
    }

    /// List of flagged metric names
    var flaggedMetrics: [String] {
        healthMonitorResult.flaggedMetrics
    }
}
