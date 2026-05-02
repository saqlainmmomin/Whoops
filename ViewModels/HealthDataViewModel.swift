import Foundation
import Combine
import HealthKit

// MARK: - HealthDataViewModel
// Pure data layer — no SwiftUI view dependencies.
// Exposes all metric data through @Published properties for Antigravity frontend consumption.
// All properties match the spec.md data contract.

@MainActor
class HealthDataViewModel: ObservableObject {
    // MARK: - Dependencies

    private let healthKitManager: HealthKitManager
    private let assessmentPipeline: DailyAssessmentPipeline

    // MARK: - Pipeline State

    @Published var pipelineState: PipelineState = .idle
    @Published var authorizationState: HealthKitAuthorizationStatus = .notDetermined
    @Published var lastRefreshDate: Date?
    @Published var errors: [PipelineError] = []

    // MARK: - Recovery Output (Tier 3 Canonical)

    @Published var recoveryScore: Int?                  // 0-100
    @Published var recoveryCategory: String?            // "Peak", "Moderate", "Low"
    @Published var recoveryConfidence: Confidence?

    // MARK: - Strain Target Output (Tier 3 Canonical)

    @Published var strainScore: Double?                 // 0-21 Whoop scale
    @Published var strainCategory: String?              // "Light", "Moderate", "High"
    @Published var strainConfidence: Confidence?

    // MARK: - Resting Heart Rate (Tier 1 Factual)

    @Published var restingHeartRate: Double?            // bpm
    @Published var restingHeartRateTrend: TrendDirection?
    @Published var restingHeartRateBaseline: Double?    // 28-day avg

    // MARK: - HRV SDNN (Tier 1 Factual)

    @Published var hrvSDNN: Double?                     // ms
    @Published var hrvTrend: TrendDirection?
    @Published var hrvBaseline: Double?                 // 28-day avg

    // MARK: - SpO2 (Tier 1 Factual — Foreground Only on Series 5)

    @Published var spo2Percentage: Double?              // 0-100%
    @Published var spo2Timestamp: Date?                 // Last reading time
    @Published var spo2Available: Bool = false           // false if no readings exist

    // MARK: - Sleep Duration (Tier 1 Factual)

    @Published var sleepDurationHours: Double?          // total hours asleep
    @Published var sleepNeededHours: Double?            // baseline target
    @Published var sleepPerformanceScore: Int?          // 0-100

    // MARK: - Sleep Stages (Tier 1 Factual)

    @Published var sleepStageDeep: Int?                 // minutes
    @Published var sleepStageREM: Int?                  // minutes
    @Published var sleepStageCore: Int?                 // minutes
    @Published var sleepStageAwake: Int?                // minutes
    @Published var sleepBedtime: Date?
    @Published var sleepWakeTime: Date?

    // MARK: - Active Energy (Tier 1 Factual)

    @Published var activeEnergyKcal: Double?            // kcal
    @Published var basalEnergyKcal: Double?             // kcal
    @Published var totalEnergyKcal: Double?             // active + basal

    // MARK: - Respiratory Rate (Tier 1 Factual)

    @Published var respiratoryRate: Double?             // breaths/min
    @Published var respiratoryRateBaseline: Double?     // 28-day avg

    // MARK: - Derived / Contextual

    @Published var baselineDaysCollected: Int = 0       // 0-28
    @Published var dataQuality: DataQualityIndicator?

    // MARK: - Weekly Trend Data (for charts)

    @Published var weeklyRecoveryScores: [Int] = []
    @Published var weeklyStrainScores: [Double] = []
    @Published var weeklyHRV: [Double] = []
    @Published var weeklyRHR: [Double] = []
    @Published var weeklySleepHours: [Double] = []
    @Published var weeklyActiveEnergy: [Double] = []

    // MARK: - Anchored Query State (for incremental updates)

    private var hrAnchor: HKQueryAnchor?
    private var hrvAnchor: HKQueryAnchor?
    private var sleepAnchor: HKQueryAnchor?

    // MARK: - Init

    init(healthKitManager: HealthKitManager) {
        self.healthKitManager = healthKitManager
        self.assessmentPipeline = DailyAssessmentPipeline(healthKitManager: healthKitManager)
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        pipelineState = .authorizing
        do {
            try await healthKitManager.requestSeries5Authorization()
            authorizationState = healthKitManager.authorizationStatus
            if authorizationState == .authorized {
                pipelineState = .idle
            } else {
                pipelineState = .authorizationDenied
            }
        } catch {
            authorizationState = .denied
            pipelineState = .authorizationDenied
            appendError(.authorizationFailed(error.localizedDescription))
        }
    }

    // MARK: - Full Data Refresh

    func refreshAllData() async {
        guard authorizationState == .authorized else {
            appendError(.authorizationRequired)
            pipelineState = .authorizationDenied
            return
        }

        pipelineState = .loading
        errors.removeAll()

        do {
            let history = try await assessmentPipeline.loadHistory(days: 28, endingOn: Date(), context: nil)
            guard let currentAssessment = history.latestAssessment else {
                appendError(.noData("daily assessment"))
                pipelineState = .error
                return
            }

            populatePublishedState(from: currentAssessment, history: history.assessments)
            await fetchSpO2Data()

            lastRefreshDate = Date()
            pipelineState = .ready
        } catch {
            appendError(.queryFailed("assessment pipeline", error.localizedDescription))
            pipelineState = .error
        }
    }

    // MARK: - Incremental Updates (Anchored Queries)

    func fetchIncrementalUpdates() async {
        guard authorizationState == .authorized else { return }

        // Heart rate updates
        do {
            let result = try await healthKitManager.fetchHeartRateUpdates(since: hrAnchor)
            if !result.samples.isEmpty {
                hrAnchor = result.newAnchor
                await refreshAllData()
            }
        } catch {
            appendError(.queryFailed("HR incremental", error.localizedDescription))
        }

        // HRV updates
        do {
            let result = try await healthKitManager.fetchHRVUpdates(since: hrvAnchor)
            if !result.samples.isEmpty {
                hrvAnchor = result.newAnchor
                if let latest = result.samples.last {
                    hrvSDNN = latest.sdnn
                }
            }
        } catch {
            appendError(.queryFailed("HRV incremental", error.localizedDescription))
        }

        // Sleep updates
        do {
            let result = try await healthKitManager.fetchSleepUpdates(since: sleepAnchor)
            if !result.samples.isEmpty {
                sleepAnchor = result.newAnchor
                await refreshAllData()
            }
        } catch {
            appendError(.queryFailed("sleep incremental", error.localizedDescription))
        }
    }

    // MARK: - Private: Populate Published State

    private func populatePublishedState(
        from assessment: DailyAssessment,
        history: [DailyAssessment]
    ) {
        let metrics = assessment.metrics
        let sevenDayBaseline = assessment.sevenDayBaseline
        let twentyEightDayBaseline = assessment.twentyEightDayBaseline

        populateHeartRateData(from: metrics)
        populateHRVData(from: metrics)
        populateSleepData(from: metrics)
        populateActivityData(from: metrics)
        populateRespiratoryData(from: metrics)

        recoveryScore = assessment.recovery?.score
        recoveryCategory = metrics.recoveryScore?.category.rawValue
        recoveryConfidence = assessment.recovery?.confidence

        strainScore = assessment.strainTarget?.recommendedTarget
        strainCategory = assessment.strainTarget?.dayType.capitalized
        strainConfidence = assessment.strainTarget?.confidence

        restingHeartRateBaseline = twentyEightDayBaseline.averageRestingHR
        hrvBaseline = twentyEightDayBaseline.averageHRV
        respiratoryRateBaseline = nil
        sleepNeededHours = twentyEightDayBaseline.averageSleepDuration ?? sevenDayBaseline.averageSleepDuration

        baselineDaysCollected = min(
            twentyEightDayBaseline.heartRateSampleDays,
            twentyEightDayBaseline.hrvSampleDays,
            twentyEightDayBaseline.sleepSampleDays,
            twentyEightDayBaseline.activitySampleDays
        )
        dataQuality = metrics.dataQuality

        let weeklyAssessments = Array(history.suffix(7))
        weeklyRecoveryScores = weeklyAssessments.compactMap { $0.recovery?.score }
        weeklyStrainScores = weeklyAssessments.compactMap { $0.strainTarget?.recommendedTarget }
        weeklyHRV = weeklyAssessments.compactMap { $0.metrics.hrv?.nightlySDNN ?? $0.metrics.hrv?.averageSDNN }
        weeklyRHR = weeklyAssessments.compactMap { $0.metrics.heartRate?.restingBPM }
        weeklySleepHours = weeklyAssessments.compactMap { $0.metrics.sleep?.totalSleepHours }
        weeklyActiveEnergy = weeklyAssessments.compactMap { $0.metrics.activity?.activeEnergy }

        calculateTrends(from: history.map(\.metrics))

        if let sleepHours = sleepDurationHours, let needed = sleepNeededHours, needed > 0 {
            let ratio = sleepHours / needed
            sleepPerformanceScore = min(100, Int((ratio * 100).rounded()))
        } else {
            sleepPerformanceScore = nil
        }
    }

    private func populateHeartRateData(from metrics: DailyMetrics) {
        restingHeartRate = metrics.heartRate?.restingBPM
    }

    private func populateHRVData(from metrics: DailyMetrics) {
        hrvSDNN = metrics.hrv?.nightlySDNN ?? metrics.hrv?.averageSDNN
    }

    private func populateSleepData(from metrics: DailyMetrics) {
        guard let sleep = metrics.sleep else {
            sleepDurationHours = nil
            sleepPerformanceScore = nil
            sleepStageDeep = nil
            sleepStageREM = nil
            sleepStageCore = nil
            sleepStageAwake = nil
            sleepBedtime = nil
            sleepWakeTime = nil
            return
        }

        sleepDurationHours = sleep.totalSleepHours
        sleepBedtime = sleep.bedtime
        sleepWakeTime = sleep.wakeTime

        let breakdown = sleep.combinedStageBreakdown
        sleepStageDeep = breakdown.deepMinutes
        sleepStageREM = breakdown.remMinutes
        sleepStageCore = breakdown.coreMinutes
        sleepStageAwake = breakdown.awakeMinutes
    }

    private func populateActivityData(from metrics: DailyMetrics) {
        activeEnergyKcal = metrics.activity?.activeEnergy
        basalEnergyKcal = metrics.activity?.basalEnergy

        if let activeEnergy = metrics.activity?.activeEnergy,
           let basalEnergy = metrics.activity?.basalEnergy {
            totalEnergyKcal = activeEnergy + basalEnergy
        } else {
            totalEnergyKcal = nil
        }
    }

    private func populateRespiratoryData(from _: DailyMetrics) {
        respiratoryRate = nil
    }

    // MARK: - Private: SpO2 Fetch

    private func fetchSpO2Data() async {
        do {
            if let latest = try await healthKitManager.fetchLatestSpO2() {
                spo2Percentage = latest.percentage
                spo2Timestamp = latest.timestamp
                spo2Available = true
            } else {
                spo2Available = false
                spo2Percentage = nil
                spo2Timestamp = nil
            }
        } catch {
            spo2Available = false
            appendError(.queryFailed("SpO2", error.localizedDescription))
        }
    }

    // MARK: - Private: Trends

    private func calculateTrends(from metrics: [DailyMetrics]) {
        // HRV trend
        if let trend = BaselineEngine.calculateHRVTrend(from: metrics) {
            hrvTrend = trend.direction
        } else {
            hrvTrend = nil
        }

        if let trend = BaselineEngine.calculateRHRTrend(from: metrics) {
            restingHeartRateTrend = trend.direction
        } else {
            restingHeartRateTrend = nil
        }
    }

    // MARK: - Error Management

    private func appendError(_ error: PipelineError) {
        errors.append(error)
    }
}

// MARK: - Pipeline State

enum PipelineState: String {
    case idle = "Idle"
    case authorizing = "Authorizing"
    case authorizationDenied = "Authorization Denied"
    case loading = "Loading"
    case ready = "Ready"
    case error = "Error"

    var isLoading: Bool { self == .loading || self == .authorizing }
    var isReady: Bool { self == .ready }
    var hasError: Bool { self == .error || self == .authorizationDenied }
}

// MARK: - Pipeline Error

enum PipelineError: Identifiable {
    case authorizationRequired
    case authorizationFailed(String)
    case queryFailed(String, String)
    case noData(String)

    var id: String {
        switch self {
        case .authorizationRequired: return "auth_required"
        case .authorizationFailed(let msg): return "auth_failed_\(msg)"
        case .queryFailed(let metric, _): return "query_\(metric)"
        case .noData(let metric): return "nodata_\(metric)"
        }
    }

    var message: String {
        switch self {
        case .authorizationRequired:
            return "HealthKit authorization is required"
        case .authorizationFailed(let reason):
            return "Authorization failed: \(reason)"
        case .queryFailed(let metric, let reason):
            return "\(metric) query failed: \(reason)"
        case .noData(let metric):
            return "No \(metric) data available"
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .authorizationRequired, .authorizationFailed: return true
        case .queryFailed: return true
        case .noData: return false
        }
    }
}
