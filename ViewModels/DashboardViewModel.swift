import Foundation
import SwiftUI
import Combine
import SwiftData

@MainActor
class DashboardViewModel: ObservableObject {
    private let healthKitManager: HealthKitManager
    private let assessmentPipeline: DailyAssessmentPipeline
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
    @Published var assessment: DailyAssessment?

    init(healthKitManager: HealthKitManager) {
        self.healthKitManager = healthKitManager
        self.assessmentPipeline = DailyAssessmentPipeline(healthKitManager: healthKitManager)
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Data Loading

    func loadTodayData() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let result = try await assessmentPipeline.load(for: Date(), context: modelContext)
            let loadedAssessment = result.assessment
            let metrics = loadedAssessment.metrics

            assessment = loadedAssessment
            sevenDayBaseline = loadedAssessment.sevenDayBaseline
            twentyEightDayBaseline = loadedAssessment.twentyEightDayBaseline
            todayMetrics = metrics
            recoveryScore = metrics.recoveryScore
            strainScore = metrics.strainScore
            sleepSummary = metrics.sleep
            weeklyMetrics = result.weeklyMetrics
            weeklyRecoveryScores = weeklyMetrics.compactMap { $0.recoveryScore?.score }
            weeklyStrainScores = weeklyMetrics.compactMap { $0.strainScore?.score }
            calculateTrends(from: weeklyMetrics)
        } catch {
            errorMessage = "Failed to load health data: \(error.localizedDescription)"
        }

        isLoading = false
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
        assessment?.strainTarget?.recommendedTarget
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
        if let assessment {
            return Insight(
                icon: assessmentInsightIcon,
                headline: assessment.headline,
                detail: assessment.primaryInsight,
                accentColor: assessmentInsightColor
            )
        }

        guard let metrics = todayMetrics else { return nil }
        return InsightGenerator.shared.getPrimaryInsight(metrics: metrics, baseline: sevenDayBaseline)
    }

    var recommendedActionText: String? {
        assessment?.recommendedAction
    }

    var assessmentWarnings: [String] {
        assessment?.warnings ?? []
    }

    var assessmentHeadline: String? {
        assessment?.headline
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

    private var assessmentInsightIcon: String {
        guard let assessment else { return "waveform.path.ecg" }
        if assessment.primaryBlocker == "Sleep debt" {
            return "moon.fill"
        }
        if let recovery = assessment.recovery, recovery.score < 40 {
            return "exclamationmark.triangle.fill"
        }
        if let strainTarget = assessment.strainTarget, strainTarget.dayType == "push" {
            return "bolt.fill"
        }
        return "arrow.up.heart.fill"
    }

    private var assessmentInsightColor: Color {
        guard let assessment else { return Theme.Colors.whoopTeal }
        switch assessment.confidence {
        case .high:
            return Theme.Colors.whoopTeal
        case .medium:
            return Theme.Colors.whoopCyan
        case .low:
            return Theme.Colors.caution
        }
    }
}
