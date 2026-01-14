import Foundation

/// Tier 2 Calculator: Deterministic Metrics (Math Only)
/// These are computed from factual metrics using defined formulas with no estimation.
struct Tier2Calculator {

    // MARK: - Activity Load Calculations

    /// Calculate acute load (7-day exponentially weighted average)
    static func calculateAcuteLoad(from dailyMetrics: [DailyMetrics]) -> Double {
        let loads = dailyMetrics.suffix(7).compactMap { calculateDailyLoad(from: $0) }
        return ActivityLoad.calculateAcuteLoad(from: loads)
    }

    /// Calculate chronic load (28-day exponentially weighted average)
    static func calculateChronicLoad(from dailyMetrics: [DailyMetrics]) -> Double {
        let loads = dailyMetrics.suffix(28).compactMap { calculateDailyLoad(from: $0) }
        return ActivityLoad.calculateChronicLoad(from: loads)
    }

    /// Calculate acute:chronic workload ratio
    static func calculateLoadRatio(acute: Double, chronic: Double) -> Double {
        guard chronic > 0 else { return 1.0 }
        return acute / chronic
    }

    /// Interpret load ratio for training risk
    static func interpretLoadRatio(_ ratio: Double) -> LoadRatioInterpretation {
        switch ratio {
        case ..<Constants.ActivityLoad.lowLoadRatio:
            return .underTraining
        case Constants.ActivityLoad.optimalLoadRatioMin...Constants.ActivityLoad.optimalLoadRatioMax:
            return .optimal
        case Constants.ActivityLoad.optimalLoadRatioMax..<Constants.ActivityLoad.highRiskLoadRatio:
            return .caution
        default:
            return .highRisk
        }
    }

    private static func calculateDailyLoad(from metrics: DailyMetrics) -> ActivityLoad? {
        let energyBurned = metrics.activity?.activeEnergy ?? 0
        let steps = metrics.activity?.steps ?? 0
        let workoutMinutes = metrics.workouts?.totalDurationMinutes ?? 0

        // Calculate workout contribution based on duration and intensity
        let workoutContribution = metrics.workouts?.strainContribution ?? 0

        // Normalize steps contribution (10k steps = 1.0)
        let stepsContribution = Double(steps) / 10000.0

        return ActivityLoad(
            date: metrics.date,
            totalActiveMinutes: workoutMinutes + Int(Double(steps) / 100), // Rough estimate
            energyBurned: energyBurned,
            stepsContribution: stepsContribution,
            workoutContribution: workoutContribution / 100.0 // Normalize to ~1.0 scale
        )
    }

    // MARK: - Sleep Debt Calculations

    /// Calculate sleep debt relative to baseline
    static func calculateSleepDebt(
        actualSleep: Double,
        baseline: Baseline
    ) -> SleepDebt? {
        guard let baselineSleep = baseline.averageSleepDuration else { return nil }

        return SleepDebt(
            actualSleepHours: actualSleep,
            baselineSleepHours: baselineSleep
        )
    }

    /// Calculate cumulative sleep debt over a period
    static func calculateCumulativeSleepDebt(
        dailySleepHours: [Double],
        targetHours: Double = 7.5
    ) -> Double {
        dailySleepHours.reduce(0) { cumulative, actual in
            cumulative + (targetHours - actual)
        }
    }

    // MARK: - HRV Deviation

    /// Calculate HRV deviation as z-score from baseline
    static func calculateHRVDeviation(
        currentHRV: Double,
        baseline: Baseline
    ) -> Double? {
        baseline.hrvZScore(for: currentHRV)
    }

    /// Interpret HRV deviation
    static func interpretHRVDeviation(_ zScore: Double) -> HRVDeviationInterpretation {
        switch zScore {
        case ..<(-1.5):
            return .significantlyLow
        case -1.5..<(-0.5):
            return .belowBaseline
        case -0.5...0.5:
            return .normal
        case 0.5..<1.5:
            return .aboveBaseline
        default:
            return .significantlyHigh
        }
    }

    // MARK: - Resting HR Deviation

    /// Calculate resting HR deviation from baseline (in bpm)
    static func calculateRHRDeviation(
        currentRHR: Double,
        baseline: Baseline
    ) -> Double? {
        baseline.rhrDeviation(from: currentRHR)
    }

    /// Interpret RHR deviation
    static func interpretRHRDeviation(_ deviation: Double) -> RHRDeviationInterpretation {
        switch deviation {
        case ..<(-5):
            return .significantlyLower
        case -5..<(-2):
            return .slightlyLower
        case -2...2:
            return .normal
        case 2..<5:
            return .slightlyElevated
        default:
            return .significantlyElevated
        }
    }

    // MARK: - Sleep Timing Consistency

    /// Calculate sleep timing consistency score (0-100)
    static func calculateSleepTimingConsistency(
        recentSleepTimings: [SleepTiming],
        baseline: Baseline
    ) -> Double {
        guard !recentSleepTimings.isEmpty else { return 0 }

        // Calculate variance in bedtime
        let bedtimes = recentSleepTimings.map { Double($0.bedtimeMinutesSinceMidnight) }
        let wakeTimes = recentSleepTimings.map { Double($0.wakeTimeMinutesSinceMidnight) }

        guard let bedtimeStdDev = bedtimes.standardDeviation,
              let wakeTimeStdDev = wakeTimes.standardDeviation else {
            return 50 // Default to middle score if insufficient data
        }

        // Lower variance = higher consistency
        // 30 min std dev = 100 score, 120 min std dev = 0 score
        // Use valid range and invert the result to achieve inverse relationship
        let bedtimeScore = 100 - StatisticalHelpers.normalizeToScale(
            value: bedtimeStdDev,
            fromRange: 30...120,
            toRange: 0...100
        )

        let wakeTimeScore = 100 - StatisticalHelpers.normalizeToScale(
            value: wakeTimeStdDev,
            fromRange: 30...120,
            toRange: 0...100
        )

        return (bedtimeScore + wakeTimeScore) / 2
    }

    // MARK: - Rolling Baselines

    /// Calculate 7-day rolling baseline
    static func calculate7DayBaseline(from metrics: [DailyMetrics], asOf date: Date) -> Baseline {
        BaselineBuilder.build7DayBaseline(from: metrics, asOf: date)
    }

    /// Calculate 28-day rolling baseline
    static func calculate28DayBaseline(from metrics: [DailyMetrics], asOf date: Date) -> Baseline {
        BaselineBuilder.build28DayBaseline(from: metrics, asOf: date)
    }

    // MARK: - Complete Tier 2 Calculation

    /// Calculate all Tier 2 metrics for a day
    static func calculateTier2Metrics(
        for dailyMetrics: inout DailyMetrics,
        historicalMetrics: [DailyMetrics],
        baseline7Day: Baseline,
        baseline28Day: Baseline
    ) {
        // Activity load
        let relevantHistory = historicalMetrics.filter { $0.date < dailyMetrics.date }
        let allMetrics = relevantHistory + [dailyMetrics]

        dailyMetrics.acuteLoad = calculateAcuteLoad(from: allMetrics)
        dailyMetrics.chronicLoad = calculateChronicLoad(from: allMetrics)

        if let acute = dailyMetrics.acuteLoad, let chronic = dailyMetrics.chronicLoad {
            dailyMetrics.loadRatio = calculateLoadRatio(acute: acute, chronic: chronic)
        }

        // Sleep debt
        if let sleepHours = dailyMetrics.sleep?.totalSleepHours {
            dailyMetrics.sleepDebt = calculateSleepDebt(
                actualSleep: sleepHours,
                baseline: baseline7Day
            )
        }

        // HRV deviation
        if let hrv = dailyMetrics.hrv?.nightlySDNN ?? dailyMetrics.hrv?.averageSDNN {
            dailyMetrics.hrvDeviation = calculateHRVDeviation(
                currentHRV: hrv,
                baseline: baseline7Day
            )
        }

        // RHR deviation
        if let rhr = dailyMetrics.heartRate?.restingBPM {
            dailyMetrics.rhrDeviation = calculateRHRDeviation(
                currentRHR: rhr,
                baseline: baseline7Day
            )
        }

        // Sleep timing consistency (requires multiple days)
        let recentSleepTimings = relevantHistory.suffix(7).compactMap { metrics -> SleepTiming? in
            guard let session = metrics.sleep?.primarySession else { return nil }
            return SleepTiming(bedtime: session.startDate, wakeTime: session.endDate)
        }

        if !recentSleepTimings.isEmpty {
            dailyMetrics.sleepTimingConsistency = calculateSleepTimingConsistency(
                recentSleepTimings: recentSleepTimings,
                baseline: baseline7Day
            )
        }
    }
}

// MARK: - Interpretation Enums

enum LoadRatioInterpretation: String {
    case underTraining = "Under Training"
    case optimal = "Optimal"
    case caution = "Caution"
    case highRisk = "High Risk"

    var description: String {
        switch self {
        case .underTraining:
            return "Training load is below your recent baseline. Consider increasing intensity."
        case .optimal:
            return "Training load is well balanced with your recent baseline."
        case .caution:
            return "Training load is elevated. Monitor recovery closely."
        case .highRisk:
            return "Training load spike detected. High injury/illness risk."
        }
    }
}

enum HRVDeviationInterpretation: String {
    case significantlyLow = "Significantly Low"
    case belowBaseline = "Below Baseline"
    case normal = "Normal"
    case aboveBaseline = "Above Baseline"
    case significantlyHigh = "Significantly High"

    var description: String {
        switch self {
        case .significantlyLow:
            return "HRV significantly below baseline. Recovery may be compromised."
        case .belowBaseline:
            return "HRV slightly below baseline."
        case .normal:
            return "HRV within normal range."
        case .aboveBaseline:
            return "HRV slightly above baseline. Good recovery indicator."
        case .significantlyHigh:
            return "HRV significantly above baseline. Well recovered."
        }
    }
}

enum RHRDeviationInterpretation: String {
    case significantlyLower = "Significantly Lower"
    case slightlyLower = "Slightly Lower"
    case normal = "Normal"
    case slightlyElevated = "Slightly Elevated"
    case significantlyElevated = "Significantly Elevated"

    var description: String {
        switch self {
        case .significantlyLower:
            return "RHR well below baseline. Good fitness indicator."
        case .slightlyLower:
            return "RHR slightly below baseline."
        case .normal:
            return "RHR within normal range."
        case .slightlyElevated:
            return "RHR slightly elevated. May indicate incomplete recovery."
        case .significantlyElevated:
            return "RHR significantly elevated. Rest recommended."
        }
    }
}
