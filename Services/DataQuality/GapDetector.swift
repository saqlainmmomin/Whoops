import Foundation

/// GapDetector: Identifies and reports data gaps and quality issues
struct GapDetector {

    // MARK: - Gap Detection

    /// Detect gaps in daily metrics over a date range
    static func detectGaps(in metrics: [DailyMetrics], expectedDateRange: DateInterval) -> [DataGap] {
        var gaps: [DataGap] = []

        let expectedDates = Set(DateHelpers.dates(
            from: expectedDateRange.start,
            to: expectedDateRange.end
        ).map { $0.startOfDay })

        let recordedDates = Set(metrics.map { $0.date.startOfDay })

        // Missing days
        let missingDates = expectedDates.subtracting(recordedDates).sorted()
        for date in missingDates {
            gaps.append(DataGap(
                date: date,
                type: .missingDay,
                severity: .moderate,
                description: "No data recorded for this day"
            ))
        }

        // Partial data days
        for metric in metrics {
            let dayGaps = detectDayGaps(metric)
            gaps.append(contentsOf: dayGaps)
        }

        return gaps.sorted { $0.date > $1.date }
    }

    /// Detect gaps within a single day's metrics
    static func detectDayGaps(_ metrics: DailyMetrics) -> [DataGap] {
        var gaps: [DataGap] = []
        let date = metrics.date

        // HRV gaps
        if metrics.hrv == nil {
            gaps.append(DataGap(
                date: date,
                type: .missingHRV,
                severity: .moderate,
                description: "No HRV data. Wear Apple Watch during sleep."
            ))
        } else if let hrv = metrics.hrv, hrv.sampleCount < Constants.DataQuality.minHRVSamplesForHighConfidence {
            gaps.append(DataGap(
                date: date,
                type: .sparseHRV,
                severity: .minor,
                description: "Limited HRV samples (\(hrv.sampleCount) recorded)"
            ))
        }

        // Sleep gaps
        if metrics.sleep == nil {
            gaps.append(DataGap(
                date: date,
                type: .missingSleep,
                severity: .moderate,
                description: "No sleep data recorded"
            ))
        } else if let sleep = metrics.sleep {
            if sleep.totalSleepHours < Constants.DataQuality.minSleepHoursForHighConfidence {
                gaps.append(DataGap(
                    date: date,
                    type: .shortSleep,
                    severity: .minor,
                    description: "Short sleep duration may affect accuracy"
                ))
            }

            // Check for stage data
            let breakdown = sleep.combinedStageBreakdown
            if breakdown.deepMinutes == 0 && breakdown.remMinutes == 0 && breakdown.coreMinutes == 0 {
                gaps.append(DataGap(
                    date: date,
                    type: .missingSleepStages,
                    severity: .minor,
                    description: "Sleep stage breakdown unavailable"
                ))
            }
        }

        // Heart rate gaps
        if metrics.heartRate == nil {
            gaps.append(DataGap(
                date: date,
                type: .missingHeartRate,
                severity: .moderate,
                description: "No heart rate data recorded"
            ))
        } else if let hr = metrics.heartRate {
            if hr.sampleCount < Constants.DataQuality.minHeartRateSamplesPerDay {
                gaps.append(DataGap(
                    date: date,
                    type: .sparseHeartRate,
                    severity: .minor,
                    description: "Limited heart rate samples"
                ))
            }

            if hr.restingBPM == nil {
                gaps.append(DataGap(
                    date: date,
                    type: .missingRestingHR,
                    severity: .minor,
                    description: "Resting heart rate not available"
                ))
            }
        }

        // Activity gaps
        if metrics.activity == nil {
            gaps.append(DataGap(
                date: date,
                type: .missingActivity,
                severity: .minor,
                description: "No activity data recorded"
            ))
        }

        return gaps
    }

    // MARK: - Quality Assessment

    /// Calculate overall data quality score for a date range
    static func assessOverallQuality(metrics: [DailyMetrics]) -> OverallDataQuality {
        guard !metrics.isEmpty else {
            return OverallDataQuality(
                score: 0,
                grade: .poor,
                hrvCoverage: 0,
                sleepCoverage: 0,
                heartRateCoverage: 0,
                activityCoverage: 0,
                recommendations: ["Start wearing your Apple Watch to collect health data"]
            )
        }

        let hrvCount = metrics.filter { $0.hrv != nil }.count
        let sleepCount = metrics.filter { $0.sleep != nil }.count
        let hrCount = metrics.filter { $0.heartRate != nil }.count
        let activityCount = metrics.filter { $0.activity != nil }.count

        let total = Double(metrics.count)

        let hrvCoverage = Double(hrvCount) / total
        let sleepCoverage = Double(sleepCount) / total
        let hrCoverage = Double(hrCount) / total
        let activityCoverage = Double(activityCount) / total

        // Weighted score (HRV and sleep are most important for recovery)
        let score = (hrvCoverage * 0.35 + sleepCoverage * 0.35 + hrCoverage * 0.2 + activityCoverage * 0.1) * 100

        let grade: DataQuality
        switch score {
        case 90...: grade = .excellent
        case 75..<90: grade = .good
        case 50..<75: grade = .fair
        default: grade = .poor
        }

        var recommendations: [String] = []

        if hrvCoverage < 0.7 {
            recommendations.append("Wear Apple Watch during sleep for better HRV tracking")
        }
        if sleepCoverage < 0.7 {
            recommendations.append("Enable sleep tracking in the Health app")
        }
        if hrCoverage < 0.8 {
            recommendations.append("Ensure Apple Watch fits snugly for heart rate accuracy")
        }
        if activityCoverage < 0.8 {
            recommendations.append("Wear Apple Watch throughout the day for activity tracking")
        }

        return OverallDataQuality(
            score: score,
            grade: grade,
            hrvCoverage: hrvCoverage,
            sleepCoverage: sleepCoverage,
            heartRateCoverage: hrCoverage,
            activityCoverage: activityCoverage,
            recommendations: recommendations
        )
    }

    // MARK: - Confidence Adjustment

    /// Adjust confidence level based on detected gaps
    static func adjustConfidence(
        baseConfidence: Confidence,
        gaps: [DataGap]
    ) -> Confidence {
        let severeGaps = gaps.filter { $0.severity == .severe }.count
        let moderateGaps = gaps.filter { $0.severity == .moderate }.count

        if severeGaps > 0 {
            return .low
        }

        if moderateGaps >= 2 {
            return baseConfidence == .high ? .medium : .low
        }

        if moderateGaps == 1 {
            return baseConfidence == .high ? .medium : baseConfidence
        }

        return baseConfidence
    }

    // MARK: - Gap Summary

    /// Generate human-readable gap summary
    static func generateGapSummary(gaps: [DataGap]) -> String {
        guard !gaps.isEmpty else {
            return "Data quality is excellent with no significant gaps."
        }

        let severeCount = gaps.filter { $0.severity == .severe }.count
        let moderateCount = gaps.filter { $0.severity == .moderate }.count
        let minorCount = gaps.filter { $0.severity == .minor }.count

        var summary = "Data Quality Summary:\n"

        if severeCount > 0 {
            summary += "- \(severeCount) critical gap(s) affecting accuracy\n"
        }
        if moderateCount > 0 {
            summary += "- \(moderateCount) moderate gap(s)\n"
        }
        if minorCount > 0 {
            summary += "- \(minorCount) minor gap(s)\n"
        }

        // Add top recommendations
        let uniqueDescriptions = Array(Set(gaps.map { $0.description })).prefix(3)
        if !uniqueDescriptions.isEmpty {
            summary += "\nRecommendations:\n"
            for desc in uniqueDescriptions {
                summary += "• \(desc)\n"
            }
        }

        return summary
    }
}

// MARK: - Supporting Types

struct DataGap: Identifiable, Sendable {
    var id: String { "\(date.timeIntervalSince1970)-\(type.rawValue)" }

    let date: Date
    let type: GapType
    let severity: GapSeverity
    let description: String
}

enum GapType: String, Sendable {
    case missingDay = "missing_day"
    case missingHRV = "missing_hrv"
    case sparseHRV = "sparse_hrv"
    case missingSleep = "missing_sleep"
    case shortSleep = "short_sleep"
    case missingSleepStages = "missing_sleep_stages"
    case missingHeartRate = "missing_hr"
    case sparseHeartRate = "sparse_hr"
    case missingRestingHR = "missing_rhr"
    case missingActivity = "missing_activity"
}

enum GapSeverity: String, Sendable {
    case minor = "Minor"
    case moderate = "Moderate"
    case severe = "Severe"
}

struct OverallDataQuality: Sendable {
    let score: Double  // 0-100
    let grade: DataQuality
    let hrvCoverage: Double
    let sleepCoverage: Double
    let heartRateCoverage: Double
    let activityCoverage: Double
    let recommendations: [String]
}
