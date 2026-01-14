import Foundation
import SwiftData

// MARK: - Pattern Detector

@MainActor
class PatternDetector {

    // Minimum sample size for pattern detection
    private let minSampleSize = 7

    /// Analyze metrics and detect patterns
    func detectPatterns(from metrics: [DailyMetrics], context: ModelContext) async -> [DetectedPattern] {
        guard metrics.count >= minSampleSize else { return [] }

        var patterns: [DetectedPattern] = []

        // 1. Sleep timing -> Recovery correlation
        if let sleepPattern = detectSleepTimingPattern(from: metrics) {
            patterns.append(sleepPattern)
        }

        // 2. Rest day -> HRV correlation
        if let restPattern = detectRestDayPattern(from: metrics) {
            patterns.append(restPattern)
        }

        // 3. Workout intensity -> Next day recovery
        if let workoutPattern = detectWorkoutRecoveryPattern(from: metrics) {
            patterns.append(workoutPattern)
        }

        // 4. Sleep consistency -> Average recovery
        if let consistencyPattern = detectConsistencyPattern(from: metrics) {
            patterns.append(consistencyPattern)
        }

        // Save patterns to SwiftData
        for pattern in patterns {
            context.insert(pattern)
        }
        try? context.save()

        return patterns
    }

    // MARK: - Sleep Timing Pattern

    private func detectSleepTimingPattern(from metrics: [DailyMetrics]) -> DetectedPattern? {
        // Pair: (bedtime in minutes from midnight, next day recovery)
        var pairs: [(bedtime: Int, recovery: Int)] = []

        for i in 0..<(metrics.count - 1) {
            guard let bedtime = metrics[i].sleep?.primarySession?.startDate,
                  let nextDayRecovery = metrics[i + 1].recoveryScore?.score else {
                continue
            }

            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: bedtime)
            let minute = calendar.component(.minute, from: bedtime)
            var minutesFromMidnight = hour * 60 + minute

            // Handle late night bedtimes (after midnight)
            if hour < 6 {
                minutesFromMidnight += 24 * 60
            }

            pairs.append((bedtime: minutesFromMidnight, recovery: nextDayRecovery))
        }

        guard pairs.count >= minSampleSize else { return nil }

        let correlation = calculateCorrelation(
            x: pairs.map { Double($0.bedtime) },
            y: pairs.map { Double($0.recovery) }
        )

        // Negative correlation expected (earlier bedtime -> better recovery)
        guard abs(correlation) >= 0.25 else { return nil }

        // Calculate impact
        let earlyBedtimes = pairs.filter { $0.bedtime < 23 * 60 } // Before 11pm
        let lateBedtimes = pairs.filter { $0.bedtime >= 23 * 60 }

        guard !earlyBedtimes.isEmpty && !lateBedtimes.isEmpty else { return nil }

        let earlyAvg = Double(earlyBedtimes.map { $0.recovery }.reduce(0, +)) / Double(earlyBedtimes.count)
        let lateAvg = Double(lateBedtimes.map { $0.recovery }.reduce(0, +)) / Double(lateBedtimes.count)
        let impact = earlyAvg - lateAvg

        guard abs(impact) >= 5 else { return nil }

        let description = impact > 0
            ? "Sleeping before 11pm correlates with \(Int(impact))% higher recovery"
            : "Later bedtimes don't seem to hurt your recovery"

        let recommendation = impact > 0
            ? "Try to get to bed before 11pm to optimize recovery"
            : "Your recovery is consistent regardless of bedtime"

        return DetectedPattern(
            patternType: "sleep_timing",
            inputMetric: "bedtime",
            outputMetric: "recovery",
            correlation: correlation,
            sampleSize: pairs.count,
            descriptionText: description,
            recommendation: recommendation,
            impactScore: impact
        )
    }

    // MARK: - Rest Day Pattern

    private func detectRestDayPattern(from metrics: [DailyMetrics]) -> DetectedPattern? {
        // Pair: (had rest day, next day HRV)
        var pairs: [(restDay: Bool, nextHRV: Double)] = []

        for i in 0..<(metrics.count - 1) {
            guard let strain = metrics[i].strainScore?.score,
                  let nextHRV = metrics[i + 1].hrv?.nightlySDNN ?? metrics[i + 1].hrv?.averageSDNN else {
                continue
            }

            let isRestDay = strain < 30
            pairs.append((restDay: isRestDay, nextHRV: nextHRV))
        }

        guard pairs.count >= minSampleSize else { return nil }

        let restDayHRVs = pairs.filter { $0.restDay }.map { $0.nextHRV }
        let nonRestDayHRVs = pairs.filter { !$0.restDay }.map { $0.nextHRV }

        guard restDayHRVs.count >= 3 && nonRestDayHRVs.count >= 3 else { return nil }

        let restAvg = restDayHRVs.reduce(0, +) / Double(restDayHRVs.count)
        let nonRestAvg = nonRestDayHRVs.reduce(0, +) / Double(nonRestDayHRVs.count)
        let impact = restAvg - nonRestAvg

        guard abs(impact) >= 3 else { return nil }

        // Correlation: 1 for rest day, 0 for non-rest day vs HRV
        let correlation = calculateCorrelation(
            x: pairs.map { $0.restDay ? 1.0 : 0.0 },
            y: pairs.map { $0.nextHRV }
        )

        let description = impact > 0
            ? "Rest days (strain < 30) correlate with +\(Int(impact))ms HRV the next day"
            : "High activity days don't seem to hurt your HRV"

        let recommendation = impact > 0
            ? "Consider scheduling rest days after high-strain workouts"
            : "Your body recovers well from activity"

        return DetectedPattern(
            patternType: "rest_day",
            inputMetric: "strain",
            outputMetric: "hrv",
            correlation: correlation,
            sampleSize: pairs.count,
            descriptionText: description,
            recommendation: recommendation,
            impactScore: impact
        )
    }

    // MARK: - Workout Recovery Pattern

    private func detectWorkoutRecoveryPattern(from metrics: [DailyMetrics]) -> DetectedPattern? {
        // Pair: (workout intensity/duration, next day recovery)
        var pairs: [(workoutLoad: Double, nextRecovery: Int)] = []

        for i in 0..<(metrics.count - 1) {
            guard let workouts = metrics[i].workouts,
                  workouts.totalWorkouts > 0,
                  let nextRecovery = metrics[i + 1].recoveryScore?.score else {
                continue
            }

            let workoutLoad = Double(workouts.totalDurationMinutes) * (Double(metrics[i].strainScore?.score ?? 50) / 50.0)
            pairs.append((workoutLoad: workoutLoad, nextRecovery: nextRecovery))
        }

        guard pairs.count >= minSampleSize else { return nil }

        let correlation = calculateCorrelation(
            x: pairs.map { $0.workoutLoad },
            y: pairs.map { Double($0.nextRecovery) }
        )

        guard abs(correlation) >= 0.2 else { return nil }

        // Group by intensity
        let sortedPairs = pairs.sorted { $0.workoutLoad < $1.workoutLoad }
        let lowIntensity = Array(sortedPairs.prefix(sortedPairs.count / 3))
        let highIntensity = Array(sortedPairs.suffix(sortedPairs.count / 3))

        guard !lowIntensity.isEmpty && !highIntensity.isEmpty else { return nil }

        let lowAvg = Double(lowIntensity.map { $0.nextRecovery }.reduce(0, +)) / Double(lowIntensity.count)
        let highAvg = Double(highIntensity.map { $0.nextRecovery }.reduce(0, +)) / Double(highIntensity.count)
        let impact = lowAvg - highAvg

        let description: String
        let recommendation: String

        if correlation < -0.2 {
            description = "High-intensity workouts correlate with \(Int(abs(impact)))% lower next-day recovery"
            recommendation = "Plan recovery days after intense sessions"
        } else {
            description = "Your recovery handles workout intensity well"
            recommendation = "Keep training consistently - your body adapts well"
        }

        return DetectedPattern(
            patternType: "workout_recovery",
            inputMetric: "workout_intensity",
            outputMetric: "recovery",
            correlation: correlation,
            sampleSize: pairs.count,
            descriptionText: description,
            recommendation: recommendation,
            impactScore: impact
        )
    }

    // MARK: - Consistency Pattern

    private func detectConsistencyPattern(from metrics: [DailyMetrics]) -> DetectedPattern? {
        guard metrics.count >= 14 else { return nil }

        // Calculate sleep timing variance
        var bedtimes: [Int] = []
        for metric in metrics {
            guard let bedtime = metric.sleep?.primarySession?.startDate else { continue }
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: bedtime)
            let minute = calendar.component(.minute, from: bedtime)
            var minutesFromMidnight = hour * 60 + minute
            if hour < 6 { minutesFromMidnight += 24 * 60 }
            bedtimes.append(minutesFromMidnight)
        }

        guard bedtimes.count >= 7 else { return nil }

        let variance = calculateVariance(bedtimes.map { Double($0) })
        let stdDev = sqrt(variance)

        // Group metrics by consistency
        let consistentDays = metrics.filter { metric in
            guard let bedtime = metric.sleep?.primarySession?.startDate else { return false }
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: bedtime)
            // Consider 10pm-11:30pm as "consistent" window
            return hour >= 22 && hour <= 23
        }

        let inconsistentDays = metrics.filter { metric in
            guard let bedtime = metric.sleep?.primarySession?.startDate else { return false }
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: bedtime)
            return hour < 22 || hour > 23
        }

        let consistentRecoveries = consistentDays.compactMap { $0.recoveryScore?.score }
        let inconsistentRecoveries = inconsistentDays.compactMap { $0.recoveryScore?.score }

        guard consistentRecoveries.count >= 3 && inconsistentRecoveries.count >= 3 else { return nil }

        let consistentAvg = Double(consistentRecoveries.reduce(0, +)) / Double(consistentRecoveries.count)
        let inconsistentAvg = Double(inconsistentRecoveries.reduce(0, +)) / Double(inconsistentRecoveries.count)
        let impact = consistentAvg - inconsistentAvg

        guard abs(impact) >= 5 else { return nil }

        let description = impact > 0
            ? "Consistent bedtime (10-11:30pm) correlates with \(Int(impact))% better recovery"
            : "Your recovery doesn't depend much on bedtime consistency"

        let recommendation = impact > 0
            ? "Try to maintain a consistent sleep schedule"
            : "Focus on sleep quality over timing"

        return DetectedPattern(
            patternType: "consistency",
            inputMetric: "sleep_consistency",
            outputMetric: "recovery",
            correlation: impact > 0 ? 0.4 : 0.1,
            sampleSize: metrics.count,
            descriptionText: description,
            recommendation: recommendation,
            impactScore: impact
        )
    }

    // MARK: - Statistical Helpers

    private func calculateCorrelation(x: [Double], y: [Double]) -> Double {
        guard x.count == y.count, x.count >= 2 else { return 0 }

        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)

        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))

        guard denominator != 0 else { return 0 }
        return numerator / denominator
    }

    private func calculateVariance(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let sumSquaredDiffs = values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +)
        return sumSquaredDiffs / Double(values.count)
    }
}
