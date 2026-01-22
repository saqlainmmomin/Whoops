import Foundation

/// Week Aggregator: Aggregates metrics for calendar week view
/// Uses calendar week boundaries, not rolling 7-day windows
struct WeekAggregator {

    // MARK: - Main Aggregation

    /// Aggregate metrics for a calendar week
    /// - Parameters:
    ///   - metrics: Array of all daily metrics
    ///   - weekStartDate: Start date of the week (typically Sunday or Monday)
    /// - Returns: WeekSummary with aggregated data
    static func aggregateWeek(
        metrics: [DailyMetrics],
        weekStartDate: Date
    ) -> WeekSummary {
        let calendar = Calendar.current

        // Generate all 7 days of the week
        let weekDays = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: weekStartDate)
        }

        // Find metrics for each day
        let weekMetrics = weekDays.compactMap { day in
            metrics.first { calendar.isDate($0.date, inSameDayAs: day) }
        }

        // Calculate averages
        let recoveryScores = weekMetrics.compactMap { $0.readinessState?.recoveryScore ?? $0.recoveryScore?.score }
        let avgRecovery = recoveryScores.isEmpty ? nil : Double(recoveryScores.reduce(0, +)) / Double(recoveryScores.count)

        let strainScores = weekMetrics.compactMap { $0.performanceOutput?.totalStrain ?? $0.strainScore.map { Double($0.score) } }
        let avgStrain = strainScores.isEmpty ? nil : strainScores.reduce(0, +) / Double(strainScores.count)

        // Calculate total sleep hours
        let sleepHours = weekMetrics.compactMap { metric -> Double? in
            if let analysis = metric.sleepAnalysis {
                return analysis.totalHours
            } else if let sleep = metric.sleep {
                return sleep.totalSleepHours
            }
            return nil
        }
        let totalSleepHours = sleepHours.reduce(0, +)

        // Calculate sleep consistency
        let sleepAnalyses = weekMetrics.compactMap { $0.sleepAnalysis }
        let sleepConsistency: ConsistencyMetrics
        if sleepAnalyses.count >= 3 {
            sleepConsistency = ConsistencyCalculator.calculate(sleepSessions: sleepAnalyses)
        } else {
            let sleepSummaries = weekMetrics.compactMap { $0.sleep }
            sleepConsistency = ConsistencyCalculator.calculate(from: sleepSummaries)
        }

        return WeekSummary(
            startDate: weekStartDate,
            days: weekMetrics,
            avgRecovery: avgRecovery,
            avgStrain: avgStrain,
            totalSleepHours: totalSleepHours,
            sleepConsistency: sleepConsistency
        )
    }

    // MARK: - Week Navigation

    /// Get the start of the current calendar week
    /// - Parameter referenceDate: The reference date (defaults to today)
    /// - Returns: Start date of the week containing the reference date
    static func currentWeekStart(from referenceDate: Date = Date()) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)
        return calendar.date(from: components) ?? referenceDate
    }

    /// Get the previous week's start date
    static func previousWeekStart(from weekStart: Date) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: -1, to: weekStart) ?? weekStart
    }

    /// Get the next week's start date
    static func nextWeekStart(from weekStart: Date) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: 1, to: weekStart) ?? weekStart
    }

    /// Check if a week is in the future
    static func isWeekInFuture(_ weekStart: Date) -> Bool {
        weekStart > currentWeekStart()
    }

    // MARK: - Multi-Week Comparison

    /// Compare two weeks of metrics
    static func compareWeeks(
        currentWeek: WeekSummary,
        previousWeek: WeekSummary
    ) -> WeekComparison {
        let recoveryChange: Double?
        if let current = currentWeek.avgRecovery, let previous = previousWeek.avgRecovery {
            recoveryChange = current - previous
        } else {
            recoveryChange = nil
        }

        let strainChange: Double?
        if let current = currentWeek.avgStrain, let previous = previousWeek.avgStrain {
            strainChange = current - previous
        } else {
            strainChange = nil
        }

        let sleepChange = currentWeek.totalSleepHours - previousWeek.totalSleepHours

        let consistencyChange = currentWeek.sleepConsistency.consistencyScore - previousWeek.sleepConsistency.consistencyScore

        return WeekComparison(
            recoveryChange: recoveryChange,
            strainChange: strainChange,
            sleepHoursChange: sleepChange,
            consistencyChange: consistencyChange
        )
    }

    // MARK: - Helper Methods

    /// Calculate average from optional doubles
    private static func average(_ values: [Double?]) -> Double? {
        let nonNil = values.compactMap { $0 }
        guard !nonNil.isEmpty else { return nil }
        return nonNil.reduce(0, +) / Double(nonNil.count)
    }

    /// Format week date range for display
    static func formatWeekRange(_ weekStart: Date) -> String {
        let calendar = Calendar.current
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return weekStart.formatted(.dateTime.month().day())
        }

        let startMonth = calendar.component(.month, from: weekStart)
        let endMonth = calendar.component(.month, from: weekEnd)

        if startMonth == endMonth {
            // Same month: "Jan 15-21"
            let startDay = weekStart.formatted(.dateTime.month(.abbreviated).day())
            let endDay = weekEnd.formatted(.dateTime.day())
            return "\(startDay)-\(endDay)"
        } else {
            // Different months: "Jan 29 - Feb 4"
            let startFormatted = weekStart.formatted(.dateTime.month(.abbreviated).day())
            let endFormatted = weekEnd.formatted(.dateTime.month(.abbreviated).day())
            return "\(startFormatted) - \(endFormatted)"
        }
    }
}

// MARK: - Week Comparison

struct WeekComparison: Sendable {
    let recoveryChange: Double?
    let strainChange: Double?
    let sleepHoursChange: Double
    let consistencyChange: Double

    var recoveryTrend: String {
        guard let change = recoveryChange else { return "N/A" }
        if change > 5 { return "Improved" }
        if change < -5 { return "Declined" }
        return "Stable"
    }

    var strainTrend: String {
        guard let change = strainChange else { return "N/A" }
        if change > 2 { return "Higher" }
        if change < -2 { return "Lower" }
        return "Similar"
    }

    var sleepTrend: String {
        if sleepHoursChange > 3.5 { return "More sleep" }
        if sleepHoursChange < -3.5 { return "Less sleep" }
        return "Similar"
    }

    var consistencyTrend: String {
        if consistencyChange > 0.1 { return "More consistent" }
        if consistencyChange < -0.1 { return "Less consistent" }
        return "Stable"
    }

    var overallInsight: String {
        var insights: [String] = []

        if let rc = recoveryChange, rc > 5 {
            insights.append("Recovery improved this week")
        } else if let rc = recoveryChange, rc < -5 {
            insights.append("Recovery declined this week")
        }

        if sleepHoursChange < -3.5 {
            insights.append("Consider getting more sleep")
        }

        if consistencyChange < -0.1 {
            insights.append("Try to maintain a more consistent sleep schedule")
        }

        return insights.isEmpty ? "Your metrics are stable week-over-week." : insights.joined(separator: ". ") + "."
    }
}
