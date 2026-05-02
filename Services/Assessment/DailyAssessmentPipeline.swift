import Foundation
import SwiftData

struct DailyAssessmentPipeline {
    private let healthKitManager: HealthKitManager
    private let metricsBuilder = DailyMetricsBuilder()

    init(healthKitManager: HealthKitManager) {
        self.healthKitManager = healthKitManager
    }

    func load(for date: Date, context: ModelContext?) async throws -> DailyAssessmentLoadResult {
        let historyResult = try await loadHistory(days: 8, endingOn: date, context: context)
        guard let assessment = historyResult.latestAssessment else {
            throw DailyAssessmentPipelineError.assessmentUnavailable(date)
        }

        return DailyAssessmentLoadResult(
            assessment: assessment,
            weeklyMetrics: historyResult.dailyMetrics
        )
    }

    func loadHistory(
        days: Int,
        endingOn endDate: Date,
        context: ModelContext?
    ) async throws -> DailyAssessmentHistoryLoadResult {
        let targetDays = max(days, 1)
        let preloadDays = targetDays + 28
        let allDates = DateHelpers.datesInLast(days: preloadDays, from: endDate)

        let baseMetrics = try await loadBaseMetrics(for: allDates, endingOn: endDate, context: context)
        let targetStartDate = allDates.suffix(targetDays).first ?? endDate.startOfDay

        var enrichedHistory: [DailyMetrics] = []
        var assessments: [DailyAssessment] = []

        for (index, baseMetric) in baseMetrics.enumerated() {
            let historicalBaseMetrics = Array(baseMetrics.prefix(index))
            let baselines = BaselineEngine.calculateBaselines(from: historicalBaseMetrics, asOf: baseMetric.date)

            let enrichedMetric = enrich(
                baseMetric,
                historicalMetrics: enrichedHistory,
                baseline7Day: baselines.sevenDay,
                baseline28Day: baselines.twentyEightDay
            )
            enrichedHistory.append(enrichedMetric)

            if let context {
                try? LocalStore.saveDailyMetrics(enrichedMetric, context: context)
            }

            guard baseMetric.date.startOfDay >= targetStartDate else { continue }

            let assessment = buildAssessment(
                from: enrichedMetric,
                historicalMetrics: Array(enrichedHistory.dropLast()),
                baseline7Day: baselines.sevenDay,
                baseline28Day: baselines.twentyEightDay
            )
            assessments.append(assessment)
        }

        return DailyAssessmentHistoryLoadResult(assessments: assessments)
    }

    private func loadBaseMetrics(
        for dates: [Date],
        endingOn endDate: Date,
        context: ModelContext?
    ) async throws -> [DailyMetrics] {
        var metricsByDate: [Date: DailyMetrics] = [:]

        for date in dates {
            if !date.isSameDay(as: endDate),
               let context,
               let cachedMetrics = try? LocalStore.fetchDailyMetrics(for: date, context: context) {
                metricsByDate[date.startOfDay] = cachedMetrics
                continue
            }

            do {
                let rawData = try await healthKitManager.fetchDailyData(for: date)
                let metrics = metricsBuilder.build(from: rawData)
                metricsByDate[date.startOfDay] = metrics

                if let context {
                    try? LocalStore.saveDailyMetrics(metrics, context: context)
                }
            } catch {
                if date.isToday {
                    throw error
                }
                // Missing historical days should lower confidence, not fail the entire pipeline.
            }
        }

        return dates.compactMap { metricsByDate[$0.startOfDay] }
    }

    private func enrich(
        _ metrics: DailyMetrics,
        historicalMetrics: [DailyMetrics],
        baseline7Day: Baseline,
        baseline28Day: Baseline
    ) -> DailyMetrics {
        var enriched = metrics

        Tier2Calculator.calculateTier2Metrics(
            for: &enriched,
            historicalMetrics: historicalMetrics,
            baseline7Day: baseline7Day,
            baseline28Day: baseline28Day
        )

        enriched.recoveryScore = RecoveryScoreEngine.calculateRecoveryScore(
            hrvDeviation: enriched.hrvDeviation,
            rhrDeviation: enriched.rhrDeviation,
            sleepDurationRatio: enriched.sleepDebt?.debtRatio,
            sleepInterruptions: enriched.sleep?.totalInterruptions,
            dataQuality: enriched.dataQuality
        )

        enriched.strainScore = StrainScoreEngine.calculateStrainScore(
            zoneDistribution: enriched.zoneDistribution,
            workoutDurationMinutes: enriched.workouts?.totalDurationMinutes ?? 0,
            activeEnergy: enriched.activity?.activeEnergy ?? 0,
            baselineActiveEnergy: baseline7Day.averageActiveEnergy,
            dataQuality: enriched.dataQuality
        )

        return enriched
    }

    private func buildAssessment(
        from metrics: DailyMetrics,
        historicalMetrics: [DailyMetrics],
        baseline7Day: Baseline,
        baseline28Day: Baseline
    ) -> DailyAssessment {
        let warnings = assessmentWarnings(
            for: metrics,
            baseline7Day: baseline7Day,
            baseline28Day: baseline28Day
        )

        let recovery = buildRecoveryAssessment(from: metrics, warnings: warnings)
        let strainTarget = buildStrainTargetAssessment(
            from: metrics,
            historicalMetrics: historicalMetrics,
            recovery: recovery
        )
        let sleepGuidance = buildSleepGuidanceAssessment(
            from: metrics,
            baseline7Day: baseline7Day,
            baseline28Day: baseline28Day,
            recovery: recovery
        )

        let primaryBlocker = resolvePrimaryBlocker(
            metrics: metrics,
            recovery: recovery,
            warnings: warnings
        )

        let primaryInsight = resolvePrimaryInsight(
            metrics: metrics,
            recovery: recovery,
            strainTarget: strainTarget,
            sleepGuidance: sleepGuidance
        )

        let recommendedAction = resolveRecommendedAction(
            recovery: recovery,
            strainTarget: strainTarget,
            sleepGuidance: sleepGuidance,
            warnings: warnings
        )

        let overallConfidence = [recovery?.confidence, strainTarget != nil ? strainTargetConfidence(from: metrics, historicalMetrics: historicalMetrics) : nil, sleepGuidance?.bedtimeConfidence]
            .compactMap { $0 }
            .min(by: { lhs, rhs in
                confidenceOrder(lhs: lhs, rhs: rhs)
            }) ?? .low

        return DailyAssessment(
            date: metrics.date,
            metrics: metrics,
            sevenDayBaseline: baseline7Day,
            twentyEightDayBaseline: baseline28Day,
            recovery: recovery,
            strainTarget: strainTarget,
            sleepGuidance: sleepGuidance,
            primaryInsight: primaryInsight,
            recommendedAction: recommendedAction,
            primaryBlocker: primaryBlocker,
            confidence: overallConfidence,
            warnings: warnings
        )
    }

    private func buildRecoveryAssessment(
        from metrics: DailyMetrics,
        warnings: [String]
    ) -> RecoveryAssessment? {
        guard let recovery = metrics.recoveryScore else { return nil }

        var explanation: [String] = []

        if let hrvDeviation = metrics.hrvDeviation {
            let direction = hrvDeviation >= 0 ? "above" : "below"
            explanation.append("HRV is \(String(format: "%.1f", abs(hrvDeviation))) SD \(direction) baseline.")
        }

        if let rhrDeviation = metrics.rhrDeviation {
            let direction = rhrDeviation <= 0 ? "below" : "above"
            explanation.append("Resting HR is \(String(format: "%.1f", abs(rhrDeviation))) bpm \(direction) baseline.")
        }

        if let sleepDebt = metrics.sleepDebt {
            explanation.append("Sleep covered \(Int((sleepDebt.debtRatio * 100).rounded()))% of baseline need.")
        }

        if explanation.isEmpty {
            explanation = warnings.isEmpty ? ["Recovery is based on limited available signals."] : warnings
        }

        let impact: String
        switch recovery.category {
        case .high:
            impact = "High-intensity work is available if load is controlled."
        case .moderate:
            impact = "Bias toward a normal or moderate training day."
        case .low:
            impact = "Reduce intensity and protect recovery today."
        }

        return RecoveryAssessment(
            score: recovery.score,
            confidence: recovery.confidence,
            explanation: explanation,
            recommendationImpact: impact
        )
    }

    private func buildStrainTargetAssessment(
        from metrics: DailyMetrics,
        historicalMetrics: [DailyMetrics],
        recovery: RecoveryAssessment?
    ) -> StrainTargetAssessment? {
        guard let recovery else { return nil }

        var target = StrainScoreEngine.calculateOptimalStrainTarget(recoveryScore: recovery.score)
        let recentLoadRatio = metrics.loadRatio ?? historicalMetrics.last?.loadRatio

        var explanation = [recovery.recommendationImpact]

        if let recentLoadRatio {
            explanation.append("Recent load ratio is \(String(format: "%.2f", recentLoadRatio)).")
            if recentLoadRatio > Constants.ActivityLoad.optimalLoadRatioMax {
                target = max(0, target - 2.0)
            } else if recentLoadRatio < Constants.ActivityLoad.lowLoadRatio, recovery.score >= 70 {
                target = min(21, target + 1.0)
            }
        } else {
            explanation.append("Recent load context is limited, so target is conservative.")
            target = max(0, target - 1.0)
        }

        if recovery.confidence == .low {
            target = max(0, target - 1.0)
            explanation.append("Recovery confidence is low, so target is narrowed.")
        }

        let lowerBound = max(0, target - 1.5)
        let upperBound = min(21, target + 1.5)

        let dayType: String
        let recommendation: String
        switch target {
        case ..<7:
            dayType = "light"
            recommendation = "Keep training easy or use today as a recovery day."
        case 7..<14:
            dayType = "moderate"
            recommendation = "Train, but keep intensity measured and avoid maximal work."
        default:
            dayType = "push"
            recommendation = "A harder day is available if you feel good during warm-up."
        }

        return StrainTargetAssessment(
            range: lowerBound...upperBound,
            recommendedTarget: target,
            dayType: dayType,
            confidence: strainTargetConfidence(from: metrics, historicalMetrics: historicalMetrics),
            explanation: explanation,
            recommendation: recommendation
        )
    }

    private func buildSleepGuidanceAssessment(
        from metrics: DailyMetrics,
        baseline7Day: Baseline,
        baseline28Day: Baseline,
        recovery: RecoveryAssessment?
    ) -> SleepGuidanceAssessment? {
        let baselineNeed = baseline28Day.averageSleepDuration ?? baseline7Day.averageSleepDuration ?? 7.5
        let debt = max(metrics.sleepDebt?.debtHours ?? 0, 0)
        let debtAdjustment = min(max(debt, 0), 1.5)
        let recoveryAdjustment = (recovery?.score ?? 100) < 40 ? 0.5 : 0
        let totalNeed = baselineNeed + debtAdjustment + recoveryAdjustment

        let bedtimeConfidence: Confidence
        let bedtime: Date?
        if let averageWakeTime = baseline28Day.averageWakeTime ?? baseline7Day.averageWakeTime {
            bedtimeConfidence = baseline28Day.confidence
            bedtime = recommendedBedtime(
                wakeTimeMinutes: averageWakeTime,
                sleepNeedHours: totalNeed,
                referenceDate: metrics.date
            )
        } else if let wakeTime = metrics.sleep?.wakeTime {
            bedtimeConfidence = .medium
            bedtime = wakeTime.addingTimeInterval(-(totalNeed * 3600))
        } else {
            bedtimeConfidence = .low
            bedtime = nil
        }

        var explanation = ["Baseline sleep need is \(String(format: "%.1f", baselineNeed)) hours."]
        if debtAdjustment > 0 {
            explanation.append("Sleep debt adds \(String(format: "%.1f", debtAdjustment)) hours tonight.")
        }
        if recoveryAdjustment > 0 {
            explanation.append("Suppressed recovery adds a small recovery buffer tonight.")
        }
        if bedtime == nil {
            explanation.append("Bedtime is approximate because no stable wake-time anchor is available.")
        }

        let recommendation: String
        if debtAdjustment > 0 || recoveryAdjustment > 0 {
            recommendation = "Prioritize an earlier night and protect sleep opportunity."
        } else {
            recommendation = "Hold a consistent bedtime to preserve recovery."
        }

        return SleepGuidanceAssessment(
            sleepNeedHours: totalNeed,
            additionalNeedHours: debtAdjustment + recoveryAdjustment,
            recommendedBedtime: bedtime,
            bedtimeConfidence: bedtimeConfidence,
            explanation: explanation,
            recommendation: recommendation
        )
    }

    private func recommendedBedtime(
        wakeTimeMinutes: Int,
        sleepNeedHours: Double,
        referenceDate: Date
    ) -> Date {
        let calendar = Calendar.current
        let wakeHour = wakeTimeMinutes / 60
        let wakeMinute = wakeTimeMinutes % 60

        var components = calendar.dateComponents([.year, .month, .day], from: referenceDate.adding(days: 1))
        components.hour = wakeHour
        components.minute = wakeMinute

        let wakeDate = calendar.date(from: components) ?? referenceDate.adding(days: 1)
        return wakeDate.addingTimeInterval(-(sleepNeedHours * 3600))
    }

    private func assessmentWarnings(
        for metrics: DailyMetrics,
        baseline7Day: Baseline,
        baseline28Day: Baseline
    ) -> [String] {
        var warnings = metrics.dataQuality.gapDescriptions

        if BaselineEngine.assessBaselineQuality(baseline7Day) != .sufficient {
            warnings.append("7-day baseline is still building.")
        }

        if BaselineEngine.assessBaselineQuality(baseline28Day) == .insufficient {
            warnings.append("28-day baseline is limited, so guidance is conservative.")
        }

        return warnings
    }

    private func resolvePrimaryBlocker(
        metrics: DailyMetrics,
        recovery: RecoveryAssessment?,
        warnings: [String]
    ) -> String? {
        if let sleepDebt = metrics.sleepDebt, sleepDebt.debtHours > 1 {
            return "Sleep debt"
        }

        if let rhrDeviation = metrics.rhrDeviation, rhrDeviation > 3 {
            return "Elevated resting heart rate"
        }

        if let hrvDeviation = metrics.hrvDeviation, hrvDeviation < -1 {
            return "Suppressed HRV"
        }

        if recovery?.confidence == .low {
            return warnings.first ?? "Low confidence"
        }

        return nil
    }

    private func resolvePrimaryInsight(
        metrics: DailyMetrics,
        recovery: RecoveryAssessment?,
        strainTarget: StrainTargetAssessment?,
        sleepGuidance: SleepGuidanceAssessment?
    ) -> String {
        if let recovery, recovery.score < 40, let blocker = resolvePrimaryBlocker(metrics: metrics, recovery: recovery, warnings: []) {
            return "Recovery is being held back by \(blocker.lowercased())."
        }

        if let strainTarget {
            return "Today supports a \(strainTarget.dayType) day with a target strain of \(String(format: "%.1f", strainTarget.recommendedTarget))."
        }

        if let sleepGuidance {
            return "Tonight’s sleep need is \(String(format: "%.1f", sleepGuidance.sleepNeedHours)) hours."
        }

        return "Assessment is limited by missing data."
    }

    private func resolveRecommendedAction(
        recovery: RecoveryAssessment?,
        strainTarget: StrainTargetAssessment?,
        sleepGuidance: SleepGuidanceAssessment?,
        warnings: [String]
    ) -> String {
        if recovery?.confidence == .low {
            return warnings.first ?? "Keep today conservative until data quality improves."
        }

        if let recovery, recovery.score < 40 {
            return sleepGuidance?.recommendation ?? "Reduce training intensity and prioritize sleep."
        }

        return strainTarget?.recommendation ?? sleepGuidance?.recommendation ?? "Hold a normal training day and maintain sleep consistency."
    }

    private func strainTargetConfidence(
        from metrics: DailyMetrics,
        historicalMetrics: [DailyMetrics]
    ) -> Confidence {
        if metrics.dataQuality.activityCompleteness < 0.5 || historicalMetrics.count < 7 {
            return .low
        }

        if metrics.dataQuality.activityCompleteness < 0.9 {
            return .medium
        }

        return .high
    }

    private func confidenceOrder(lhs: Confidence, rhs: Confidence) -> Bool {
        confidenceRank(lhs) < confidenceRank(rhs)
    }

    private func confidenceRank(_ confidence: Confidence) -> Int {
        switch confidence {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }
}

enum DailyAssessmentPipelineError: LocalizedError {
    case assessmentUnavailable(Date)

    var errorDescription: String? {
        switch self {
        case .assessmentUnavailable(let date):
            return "No daily assessment could be built for \(DateHelpers.relativeDescription(date))."
        }
    }
}
