import Foundation

/// Sleep Performance Engine: Calculates sleep quality score based on Whoop methodology
/// Formula: Sleep Performance = 0.4 × (hours/need) + 0.3 × efficiency + 0.3 × (1 - consistency_variance)
struct SleepPerformanceEngine {

    // MARK: - Main Calculation

    /// Calculate sleep performance score
    /// - Parameters:
    ///   - hoursSlept: Actual hours of sleep
    ///   - hoursNeeded: Target hours needed (from baseline or default 7-8)
    ///   - efficiency: Sleep efficiency as 0-1 ratio (time asleep / time in bed)
    ///   - bedtimeVariance: Standard deviation of bedtimes over 7 days (seconds)
    ///   - wakeTimeVariance: Standard deviation of wake times over 7 days (seconds)
    /// - Returns: SleepPerformance containing score and component breakdown
    static func calculate(
        hoursSlept: Double,
        hoursNeeded: Double,
        efficiency: Double,
        bedtimeVariance: TimeInterval,
        wakeTimeVariance: TimeInterval
    ) -> SleepPerformance {
        // Hours component (40% weight)
        // Ratio capped at 1.5 to prevent oversleep bonus
        let hoursRatio = min(hoursSlept / max(hoursNeeded, 1), 1.5)
        let hoursComponent = hoursRatio * 0.4

        // Efficiency component (30% weight)
        // Efficiency is already 0-1, use directly
        let clampedEfficiency = StatisticalHelpers.clamp(efficiency, to: 0.0...1.0)
        let efficiencyComponent = clampedEfficiency * 0.3

        // Consistency component (30% weight)
        // Normalize variance: 0 variance = 1.0 score, 2hr+ total variance = 0
        let totalVarianceHours = (bedtimeVariance + wakeTimeVariance) / 3600
        let consistencyScore = max(0, 1 - (totalVarianceHours / 4))
        let consistencyComponent = consistencyScore * 0.3

        // Total performance score (0-100)
        let performance = (hoursComponent + efficiencyComponent + consistencyComponent) * 100

        return SleepPerformance(
            score: Int(performance.rounded()),
            hoursVsNeed: hoursSlept / max(hoursNeeded, 1),
            efficiency: clampedEfficiency,
            consistency: consistencyScore
        )
    }

    // MARK: - Convenience Methods

    /// Calculate with default hours needed (7.5 hours)
    static func calculate(
        hoursSlept: Double,
        efficiency: Double,
        bedtimeVariance: TimeInterval,
        wakeTimeVariance: TimeInterval
    ) -> SleepPerformance {
        calculate(
            hoursSlept: hoursSlept,
            hoursNeeded: 7.5,
            efficiency: efficiency,
            bedtimeVariance: bedtimeVariance,
            wakeTimeVariance: wakeTimeVariance
        )
    }

    /// Calculate from SleepAnalysis and ConsistencyMetrics
    static func calculate(
        from sleep: SleepAnalysis,
        consistency: ConsistencyMetrics
    ) -> SleepPerformance {
        calculate(
            hoursSlept: sleep.totalHours,
            hoursNeeded: sleep.hoursNeeded,
            efficiency: sleep.efficiency,
            bedtimeVariance: consistency.bedtimeVariance,
            wakeTimeVariance: consistency.wakeTimeVariance
        )
    }

    // MARK: - Hours Needed Estimation

    /// Estimate sleep hours needed based on age and activity level
    /// - Parameters:
    ///   - age: User's age in years
    ///   - highActivityDays: Number of high-strain days in past 7
    /// - Returns: Recommended hours of sleep
    static func estimateHoursNeeded(age: Int, highActivityDays: Int = 0) -> Double {
        // Base requirement by age (CDC guidelines)
        let baseHours: Double
        switch age {
        case ..<18:
            baseHours = 9.0
        case 18..<26:
            baseHours = 8.0
        case 26..<65:
            baseHours = 7.5
        default:
            baseHours = 7.0
        }

        // Add adjustment for high activity (0.25h per high-strain day, max 1h)
        let activityAdjustment = min(Double(highActivityDays) * 0.25, 1.0)

        return baseHours + activityAdjustment
    }

    // MARK: - Sleep Debt Calculation

    /// Calculate cumulative sleep debt over a period
    /// - Parameters:
    ///   - sleepHistory: Array of (hoursSlept, hoursNeeded) tuples
    /// - Returns: Total sleep debt in hours (positive = debt, negative = surplus)
    static func calculateSleepDebt(sleepHistory: [(hoursSlept: Double, hoursNeeded: Double)]) -> Double {
        sleepHistory.reduce(0) { debt, day in
            debt + (day.hoursNeeded - day.hoursSlept)
        }
    }

    /// Calculate if sleep debt is recoverable in one night
    /// - Parameter currentDebt: Current sleep debt in hours
    /// - Returns: Whether debt can be recovered with one good night's sleep
    static func isDebtRecoverable(currentDebt: Double) -> Bool {
        // Generally, 1-2 hours of debt can be recovered in one night
        // More than that requires multiple nights
        currentDebt <= 2.0
    }
}

// MARK: - Sleep Performance Categories

extension SleepPerformance {
    /// Get actionable insight based on performance score
    var insight: String {
        switch score {
        case 90...100:
            return "Excellent sleep. Your body is well-rested and ready for high performance."
        case 80..<90:
            return "Great sleep quality. You should feel refreshed and recovered."
        case 70..<80:
            return "Adequate sleep. Consider improving consistency or duration."
        case 60..<70:
            return "Sleep could be better. Focus on getting to bed earlier."
        default:
            return "Poor sleep quality detected. Prioritize rest today."
        }
    }

    /// Get recommended action based on performance
    var recommendedAction: String {
        if efficiency < 0.85 {
            return "Improve sleep environment to increase efficiency"
        } else if consistency < 0.7 {
            return "Maintain consistent bed and wake times"
        } else if hoursVsNeed < 0.9 {
            return "Aim for 30 more minutes of sleep"
        }
        return "Maintain current sleep habits"
    }
}
