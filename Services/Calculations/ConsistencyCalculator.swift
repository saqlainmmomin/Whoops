import Foundation

/// Consistency Calculator: Measures sleep schedule regularity
/// Consistency Variance = stdev(bedtimes) + stdev(wake_times) over 7 days
struct ConsistencyCalculator {

    // MARK: - Main Calculation

    /// Calculate consistency metrics from sleep sessions
    /// - Parameter sleepSessions: Array of SleepAnalysis for past 7 days
    /// - Returns: ConsistencyMetrics with variance and score
    static func calculate(sleepSessions: [SleepAnalysis]) -> ConsistencyMetrics {
        guard sleepSessions.count >= 3 else {
            return ConsistencyMetrics(
                bedtimeVariance: 0,
                wakeTimeVariance: 0,
                consistencyScore: 1.0,
                insufficientData: true
            )
        }

        // Extract bedtimes and wake times as time intervals since reference date
        let bedtimes = sleepSessions.map { $0.bedtime.timeIntervalSinceReferenceDate }
        let wakeTimes = sleepSessions.map { $0.wakeTime.timeIntervalSinceReferenceDate }

        // Normalize to time-of-day (handle midnight crossings)
        let normalizedBedtimes = normalizeBedtimes(sleepSessions.map { $0.bedtime })
        let normalizedWakeTimes = normalizeWakeTimes(sleepSessions.map { $0.wakeTime })

        // Calculate standard deviations
        let bedtimeStdev = standardDeviation(normalizedBedtimes)
        let wakeTimeStdev = standardDeviation(normalizedWakeTimes)

        // Score: perfect consistency (0 variance) = 100%, 2hr total variance = 0%
        let totalVarianceHours = (bedtimeStdev + wakeTimeStdev) / 3600
        let score = max(0, min(1, 1 - (totalVarianceHours / 4)))

        return ConsistencyMetrics(
            bedtimeVariance: bedtimeStdev,
            wakeTimeVariance: wakeTimeStdev,
            consistencyScore: score,
            insufficientData: false
        )
    }

    /// Calculate from DailySleepSummary array
    static func calculate(from summaries: [DailySleepSummary]) -> ConsistencyMetrics {
        guard summaries.count >= 3 else {
            return ConsistencyMetrics(
                bedtimeVariance: 0,
                wakeTimeVariance: 0,
                consistencyScore: 1.0,
                insufficientData: true
            )
        }

        // Extract bedtimes and wake times from primary sessions
        let bedtimes = summaries.compactMap { $0.bedtime }
        let wakeTimes = summaries.compactMap { $0.wakeTime }

        guard bedtimes.count >= 3, wakeTimes.count >= 3 else {
            return ConsistencyMetrics(
                bedtimeVariance: 0,
                wakeTimeVariance: 0,
                consistencyScore: 1.0,
                insufficientData: true
            )
        }

        let normalizedBedtimes = normalizeBedtimes(bedtimes)
        let normalizedWakeTimes = normalizeWakeTimes(wakeTimes)

        let bedtimeStdev = standardDeviation(normalizedBedtimes)
        let wakeTimeStdev = standardDeviation(normalizedWakeTimes)

        let totalVarianceHours = (bedtimeStdev + wakeTimeStdev) / 3600
        let score = max(0, min(1, 1 - (totalVarianceHours / 4)))

        return ConsistencyMetrics(
            bedtimeVariance: bedtimeStdev,
            wakeTimeVariance: wakeTimeStdev,
            consistencyScore: score,
            insufficientData: false
        )
    }

    // MARK: - Statistical Helpers

    /// Calculate standard deviation of values
    private static func standardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }

        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }

    /// Normalize bedtimes to handle midnight crossings
    /// Converts times to minutes relative to midnight, with evening times as negative
    private static func normalizeBedtimes(_ dates: [Date]) -> [Double] {
        dates.map { date -> Double in
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)

            // Convert to seconds from midnight
            // Evening times (after 6pm) become negative (before next midnight)
            if hour >= 18 {
                return Double((hour - 24) * 3600 + minute * 60)
            } else {
                return Double(hour * 3600 + minute * 60)
            }
        }
    }

    /// Normalize wake times to seconds from midnight
    private static func normalizeWakeTimes(_ dates: [Date]) -> [Double] {
        dates.map { date -> Double in
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            return Double(hour * 3600 + minute * 60)
        }
    }

    // MARK: - Analysis Methods

    /// Analyze consistency trend over multiple weeks
    static func analyzeConsistencyTrend(weeklyScores: [Double]) -> ConsistencyTrend {
        guard weeklyScores.count >= 2 else {
            return ConsistencyTrend(direction: .stable, change: 0, insight: "Not enough data for trend analysis")
        }

        let recent = weeklyScores.suffix(2)
        guard let current = recent.last, let previous = recent.dropLast().last else {
            return ConsistencyTrend(direction: .stable, change: 0, insight: "Not enough data for trend analysis")
        }

        let change = current - previous

        let direction: TrendDirection
        let insight: String

        if change > 0.1 {
            direction = .improving
            insight = "Your sleep schedule is becoming more consistent. Keep it up!"
        } else if change < -0.1 {
            direction = .declining
            insight = "Your sleep schedule has been less consistent. Try setting a fixed bedtime."
        } else {
            direction = .stable
            insight = "Your sleep consistency has been stable."
        }

        return ConsistencyTrend(direction: direction, change: change, insight: insight)
    }

    /// Get consistency category
    static func category(for score: Double) -> ConsistencyCategory {
        switch score {
        case 0.8...1.0:
            return .excellent
        case 0.6..<0.8:
            return .good
        case 0.4..<0.6:
            return .fair
        default:
            return .poor
        }
    }
}

// MARK: - Supporting Types

struct ConsistencyTrend: Sendable {
    let direction: TrendDirection
    let change: Double
    let insight: String
}

enum ConsistencyCategory: String, Sendable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"

    var description: String {
        switch self {
        case .excellent:
            return "Highly consistent sleep schedule"
        case .good:
            return "Generally consistent sleep timing"
        case .fair:
            return "Some variability in sleep schedule"
        case .poor:
            return "Irregular sleep schedule"
        }
    }

    var recommendation: String {
        switch self {
        case .excellent:
            return "Maintain your current sleep schedule."
        case .good:
            return "Try to be more consistent on weekends."
        case .fair:
            return "Set a fixed bedtime and stick to it."
        case .poor:
            return "Prioritize a regular sleep schedule for better recovery."
        }
    }
}
