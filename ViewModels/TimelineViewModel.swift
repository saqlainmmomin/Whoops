import Foundation
import SwiftUI
import SwiftData
import Combine

enum TimelineRange: String, CaseIterable {
    case week = "7 Days"
    case month = "28 Days"
    case quarter = "90 Days"

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 28
        case .quarter: return 90
        }
    }
}

@MainActor
class TimelineViewModel: ObservableObject {
    @Published var dailyMetrics: [DailyMetrics] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var timeRange: TimelineRange = .month {
        didSet {
            if let manager = lastHealthKitManager, let context = lastModelContext {
                Task {
                    await loadData(healthKitManager: manager, modelContext: context)
                }
            }
        }
    }

    @Published var baseline: Baseline?

    private var lastHealthKitManager: HealthKitManager?
    private var lastModelContext: ModelContext?

    // MARK: - Data Loading

    func loadData(healthKitManager: HealthKitManager, modelContext: ModelContext) async {
        lastHealthKitManager = healthKitManager
        lastModelContext = modelContext

        isLoading = true
        errorMessage = nil

        do {
            let dates = DateHelpers.datesInLast(days: timeRange.days, from: Date())
            var metrics: [DailyMetrics] = []

            for date in dates {
                if let cached = await loadCachedMetrics(for: date, context: modelContext) {
                    metrics.append(cached)
                } else if !date.isToday {
                    // Only fetch from HealthKit if not today (today is handled by dashboard)
                    let rawData = try await healthKitManager.fetchDailyData(for: date)
                    let processed = processRawData(rawData, historicalMetrics: metrics)
                    metrics.append(processed)
                    await cacheMetrics(processed, context: modelContext)
                }
            }

            // Calculate baseline from loaded metrics
            baseline = BaselineBuilder.build7DayBaseline(from: metrics, asOf: Date())

            // Calculate Tier 2 and scores for each day
            for i in metrics.indices {
                var metric = metrics[i]
                let historical = Array(metrics[0..<i])

                if let baseline = baseline {
                    Tier2Calculator.calculateTier2Metrics(
                        for: &metric,
                        historicalMetrics: historical,
                        baseline7Day: baseline,
                        baseline28Day: baseline
                    )
                }

                // Calculate scores if not already present
                if metric.recoveryScore == nil, let baseline = baseline {
                    metric.recoveryScore = calculateRecoveryScore(for: metric, baseline: baseline)
                }

                if metric.strainScore == nil, let baseline = baseline {
                    metric.strainScore = calculateStrainScore(for: metric, baseline: baseline)
                }

                metrics[i] = metric
            }

            dailyMetrics = metrics.sorted { $0.date > $1.date }

        } catch {
            errorMessage = "Failed to load timeline: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Week Summary

    struct WeekSummary {
        let averageRecovery: Int?
        let averageStrain: Int?
        let totalSleepHours: Double
        let totalWorkoutMinutes: Int
    }

    func weekSummary(for weekStart: Date) -> WeekSummary? {
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart)!
        let weekMetrics = dailyMetrics.filter { $0.date >= weekStart && $0.date < weekEnd }

        guard !weekMetrics.isEmpty else { return nil }

        let recoveryScores = weekMetrics.compactMap { $0.recoveryScore?.score }
        let strainScores = weekMetrics.compactMap { $0.strainScore?.score }
        let sleepHours = weekMetrics.compactMap { $0.sleep?.totalSleepHours }
        let workoutMinutes = weekMetrics.compactMap { $0.workouts?.totalDurationMinutes }

        return WeekSummary(
            averageRecovery: recoveryScores.isEmpty ? nil : recoveryScores.reduce(0, +) / recoveryScores.count,
            averageStrain: strainScores.isEmpty ? nil : strainScores.reduce(0, +) / strainScores.count,
            totalSleepHours: sleepHours.reduce(0, +),
            totalWorkoutMinutes: workoutMinutes.reduce(0, +)
        )
    }

    // MARK: - Private Helpers

    private func loadCachedMetrics(for date: Date, context: ModelContext) async -> DailyMetrics? {
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

    private func cacheMetrics(_ metrics: DailyMetrics, context: ModelContext) async {
        do {
            let record = try DailyMetricsRecord(date: metrics.date.startOfDay, metrics: metrics)
            context.insert(record)
            try context.save()
        } catch {
            print("Failed to cache metrics: \(error)")
        }
    }

    private func processRawData(_ raw: RawDailyHealthData, historicalMetrics: [DailyMetrics]) -> DailyMetrics {
        let date = raw.date
        let sleepWindow = DateHelpers.sleepWindow(for: date)

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
            hrRecovery: nil,
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
}
