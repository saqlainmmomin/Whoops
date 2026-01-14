import Foundation

/// Engine for calculating and managing rolling baselines
struct BaselineEngine {

    // MARK: - Baseline Calculation

    /// Calculate both 7-day and 28-day baselines for a given date
    static func calculateBaselines(
        from metrics: [DailyMetrics],
        asOf date: Date
    ) -> (sevenDay: Baseline, twentyEightDay: Baseline) {
        let sevenDay = BaselineBuilder.build7DayBaseline(from: metrics, asOf: date)
        let twentyEightDay = BaselineBuilder.build28DayBaseline(from: metrics, asOf: date)
        return (sevenDay, twentyEightDay)
    }

    /// Check if baselines need recalculation
    static func shouldRecalculateBaseline(
        existing: Baseline?,
        currentDate: Date
    ) -> Bool {
        guard let baseline = existing else { return true }

        // Recalculate if baseline is from a different day
        return !DateHelpers.isSameDay(baseline.calculatedDate, currentDate)
    }

    // MARK: - Baseline Quality Assessment

    /// Assess whether baseline has sufficient data for reliable calculations
    static func assessBaselineQuality(_ baseline: Baseline) -> BaselineQuality {
        let minDays = baseline.windowDays == 7
            ? Constants.DataQuality.minDaysFor7DayBaseline
            : Constants.DataQuality.minDaysFor28DayBaseline

        let totalDataDays = min(
            baseline.heartRateSampleDays,
            baseline.hrvSampleDays,
            baseline.sleepSampleDays,
            baseline.activitySampleDays
        )

        if totalDataDays >= minDays {
            return .sufficient
        } else if totalDataDays >= minDays / 2 {
            return .limited
        } else {
            return .insufficient
        }
    }

    // MARK: - Trend Detection

    /// Detect trend direction for a metric over time
    static func detectTrend(
        values: [Double],
        windowDays: Int = 7
    ) -> (direction: TrendDirection, slope: Double)? {
        guard values.count >= 3 else { return nil }

        let recentValues = Array(values.suffix(windowDays))
        guard let regression = StatisticalHelpers.linearRegression(recentValues) else {
            return nil
        }

        // Determine significance threshold based on value scale
        guard let mean = recentValues.mean else { return nil }
        let threshold = mean * 0.02 // 2% of mean as threshold

        let direction = StatisticalHelpers.trendDirection(slope: regression.slope, threshold: threshold)
        return (direction, regression.slope)
    }

    /// Calculate HRV trend over specified days
    static func calculateHRVTrend(
        from metrics: [DailyMetrics],
        windowDays: Int = 7
    ) -> (direction: TrendDirection, confidence: Double)? {
        let hrvValues = metrics.suffix(windowDays).compactMap { $0.hrv?.nightlySDNN ?? $0.hrv?.averageSDNN }
        guard hrvValues.count >= 3 else { return nil }

        guard let trend = detectTrend(values: hrvValues, windowDays: windowDays) else {
            return nil
        }

        // Confidence based on sample size
        let confidence = Double(hrvValues.count) / Double(windowDays)

        return (trend.direction, confidence)
    }

    /// Calculate resting HR trend over specified days
    static func calculateRHRTrend(
        from metrics: [DailyMetrics],
        windowDays: Int = 7
    ) -> (direction: TrendDirection, confidence: Double)? {
        let rhrValues = metrics.suffix(windowDays).compactMap { $0.heartRate?.restingBPM }
        guard rhrValues.count >= 3 else { return nil }

        guard let trend = detectTrend(values: rhrValues, windowDays: windowDays) else {
            return nil
        }

        // For RHR, declining is improving (lower is better)
        let direction: TrendDirection = {
            switch trend.direction {
            case .improving: return .declining  // Lower RHR = improving
            case .declining: return .improving  // Higher RHR = declining
            case .stable: return .stable
            }
        }()

        let confidence = Double(rhrValues.count) / Double(windowDays)
        return (direction, confidence)
    }

    /// Calculate sleep duration trend
    static func calculateSleepTrend(
        from metrics: [DailyMetrics],
        windowDays: Int = 7
    ) -> (direction: TrendDirection, confidence: Double)? {
        let sleepValues = metrics.suffix(windowDays).compactMap { $0.sleep?.totalSleepHours }
        guard sleepValues.count >= 3 else { return nil }

        guard let trend = detectTrend(values: sleepValues, windowDays: windowDays) else {
            return nil
        }

        let confidence = Double(sleepValues.count) / Double(windowDays)
        return (trend.direction, confidence)
    }

    // MARK: - Baseline Comparison

    /// Compare current value to baseline with interpretation
    static func compareToBaseline<T: Comparable & Numeric>(
        current: T,
        baselineAverage: T?,
        baselineStdDev: Double?,
        higherIsBetter: Bool = true
    ) -> BaselineComparison? {
        guard let avg = baselineAverage else { return nil }

        let numericCurrent = Double("\(current)") ?? 0
        let numericAvg = Double("\(avg)") ?? 0

        let difference = numericCurrent - numericAvg
        let percentChange = numericAvg != 0 ? (difference / numericAvg) * 100 : 0

        let status: ComparisonStatus
        if let std = baselineStdDev, std > 0 {
            let zScore = difference / std
            status = interpretZScore(zScore, higherIsBetter: higherIsBetter)
        } else {
            status = interpretPercentChange(percentChange, higherIsBetter: higherIsBetter)
        }

        return BaselineComparison(
            currentValue: numericCurrent,
            baselineValue: numericAvg,
            difference: difference,
            percentChange: percentChange,
            status: status
        )
    }

    private static func interpretZScore(_ zScore: Double, higherIsBetter: Bool) -> ComparisonStatus {
        let adjustedZScore = higherIsBetter ? zScore : -zScore

        switch adjustedZScore {
        case ..<(-1.5): return .significantlyWorse
        case -1.5..<(-0.5): return .slightlyWorse
        case -0.5...0.5: return .similar
        case 0.5..<1.5: return .slightlyBetter
        default: return .significantlyBetter
        }
    }

    private static func interpretPercentChange(_ change: Double, higherIsBetter: Bool) -> ComparisonStatus {
        let adjustedChange = higherIsBetter ? change : -change

        switch adjustedChange {
        case ..<(-15): return .significantlyWorse
        case -15..<(-5): return .slightlyWorse
        case -5...5: return .similar
        case 5..<15: return .slightlyBetter
        default: return .significantlyBetter
        }
    }
}

// MARK: - Supporting Types

enum BaselineQuality: String {
    case insufficient = "Insufficient"
    case limited = "Limited"
    case sufficient = "Sufficient"

    var description: String {
        switch self {
        case .insufficient:
            return "Not enough data for reliable baseline. Continue wearing your device."
        case .limited:
            return "Limited data available. Baseline accuracy will improve over time."
        case .sufficient:
            return "Baseline is reliable based on available data."
        }
    }
}

struct BaselineComparison {
    let currentValue: Double
    let baselineValue: Double
    let difference: Double
    let percentChange: Double
    let status: ComparisonStatus

    var formattedDifference: String {
        let sign = difference >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", difference))"
    }

    var formattedPercentChange: String {
        let sign = percentChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", percentChange))%"
    }
}

enum ComparisonStatus: String {
    case significantlyBetter = "Much Better"
    case slightlyBetter = "Better"
    case similar = "Similar"
    case slightlyWorse = "Worse"
    case significantlyWorse = "Much Worse"

    var isPositive: Bool {
        self == .significantlyBetter || self == .slightlyBetter
    }

    var isNegative: Bool {
        self == .significantlyWorse || self == .slightlyWorse
    }
}
