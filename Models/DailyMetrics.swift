import Foundation
import SwiftData

// MARK: - Daily Metrics (Main Aggregate Model)

struct DailyMetrics: Identifiable, Sendable {
    var id: Date { date }

    let date: Date

    // Tier 1: Factual Metrics
    let heartRate: DailyHeartRateSummary?
    let hrv: DailyHRVSummary?
    let sleep: DailySleepSummary?
    let workouts: DailyWorkoutSummary?
    let activity: DailyActivitySummary?
    let zoneDistribution: ZoneTimeDistribution?
    let hrRecovery: HRRecoveryData?

    // Tier 2: Deterministic Metrics
    var acuteLoad: Double?
    var chronicLoad: Double?
    var loadRatio: Double?
    var sleepDebt: SleepDebt?
    var hrvDeviation: Double?  // z-score from baseline
    var rhrDeviation: Double?  // bpm delta from baseline
    var sleepTimingConsistency: Double?  // 0-100 score

    // Tier 3: Inferred Metrics
    var recoveryScore: RecoveryScore?
    var strainScore: StrainScore?

    // Data Quality
    var dataQuality: DataQualityIndicator

    // Computed properties
    var hasHeartRateData: Bool { heartRate != nil }
    var hasHRVData: Bool { hrv != nil }
    var hasSleepData: Bool { sleep != nil }
    var hasWorkoutData: Bool { workouts != nil && workouts!.totalWorkouts > 0 }
    var hasActivityData: Bool { activity != nil }

    var primaryMetricsSummary: String {
        var parts: [String] = []
        if let recovery = recoveryScore {
            parts.append("Recovery: \(recovery.score)")
        }
        if let strain = strainScore {
            parts.append("Strain: \(strain.score)")
        }
        if let sleep = sleep {
            parts.append(String(format: "Sleep: %.1fh", sleep.totalSleepHours))
        }
        return parts.joined(separator: " | ")
    }
}

extension DailyMetrics: Codable {}

extension DailyMetrics {
    static func placeholder(for date: Date) -> DailyMetrics {
        DailyMetrics(
            date: date,
            heartRate: DailyHeartRateSummary(
                date: date,
                averageBPM: 72,
                minBPM: 48,
                maxBPM: 165,
                restingBPM: 58,
                sampleCount: 1440
            ),
            hrv: DailyHRVSummary(
                date: date,
                averageSDNN: 45,
                minSDNN: 25,
                maxSDNN: 85,
                nightlySDNN: 52,
                sampleCount: 48
            ),
            sleep: nil,
            workouts: nil,
            activity: DailyActivitySummary(
                date: date,
                steps: 8500,
                distance: 6.2,
                activeEnergy: 450,
                basalEnergy: 1800
            ),
            zoneDistribution: nil,
            hrRecovery: nil,
            acuteLoad: nil,
            chronicLoad: nil,
            loadRatio: nil,
            sleepDebt: nil,
            hrvDeviation: nil,
            rhrDeviation: nil,
            sleepTimingConsistency: nil,
            recoveryScore: RecoveryScore(
                score: 65,
                confidence: .medium,
                hrvComponent: ScoreComponent(name: "HRV", rawValue: 52, normalizedValue: 65, weight: 0.4, contribution: 26),
                rhrComponent: ScoreComponent(name: "RHR", rawValue: 58, normalizedValue: 70, weight: 0.2, contribution: 14),
                sleepDurationComponent: ScoreComponent(name: "Sleep", rawValue: 7.2, normalizedValue: 60, weight: 0.25, contribution: 15),
                sleepInterruptionComponent: ScoreComponent(name: "Interruptions", rawValue: 2, normalizedValue: 50, weight: 0.15, contribution: 10)
            ),
            strainScore: StrainScore(
                score: 45,
                confidence: .medium,
                zoneComponent: ScoreComponent(name: "Zones", rawValue: 35, normalizedValue: 50, weight: 0.5, contribution: 25),
                durationComponent: ScoreComponent(name: "Duration", rawValue: 45, normalizedValue: 40, weight: 0.3, contribution: 12),
                energyComponent: ScoreComponent(name: "Energy", rawValue: 450, normalizedValue: 40, weight: 0.2, contribution: 8),
                weeklyAccumulation: nil
            ),
            dataQuality: DataQualityIndicator(
                heartRateCompleteness: 0.85,
                hrvCompleteness: 0.75,
                sleepCompleteness: 0.0,
                activityCompleteness: 0.9
            )
        )
    }
}

// MARK: - Recovery Score

struct RecoveryScore: Codable, Sendable {
    let score: Int  // 0-100
    let confidence: Confidence

    // Component breakdown for transparency
    let hrvComponent: ScoreComponent
    let rhrComponent: ScoreComponent
    let sleepDurationComponent: ScoreComponent
    let sleepInterruptionComponent: ScoreComponent

    var components: [ScoreComponent] {
        [hrvComponent, rhrComponent, sleepDurationComponent, sleepInterruptionComponent]
    }

    var category: RecoveryCategory {
        switch score {
        case 0..<33: return .low
        case 33..<67: return .moderate
        default: return .high
        }
    }
}

enum RecoveryCategory: String, Codable, Sendable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"

    var description: String {
        switch self {
        case .low: return "Your body may need more rest"
        case .moderate: return "Ready for moderate activity"
        case .high: return "Well recovered, ready for high intensity"
        }
    }
}

// MARK: - Strain Score

struct StrainScore: Codable, Sendable {
    let score: Int  // 0-100
    let confidence: Confidence

    // Component breakdown for transparency
    let zoneComponent: ScoreComponent
    let durationComponent: ScoreComponent
    let energyComponent: ScoreComponent

    var components: [ScoreComponent] {
        [zoneComponent, durationComponent, energyComponent]
    }

    var category: StrainCategory {
        switch score {
        case 0..<33: return .light
        case 33..<67: return .moderate
        default: return .high
        }
    }

    // 7-day cumulative strain
    var weeklyAccumulation: Double?
}

enum StrainCategory: String, Codable, Sendable {
    case light = "Light"
    case moderate = "Moderate"
    case high = "High"

    var description: String {
        switch self {
        case .light: return "Low cardiovascular load"
        case .moderate: return "Balanced training load"
        case .high: return "Significant cardiovascular demand"
        }
    }
}

// MARK: - Score Component (for transparency)

struct ScoreComponent: Codable, Identifiable, Sendable {
    var id: String { name }

    let name: String
    let rawValue: Double
    let normalizedValue: Double  // 0-100 scale
    let weight: Double  // Contribution weight (sum to 1.0)
    let contribution: Double  // Actual points contributed

    var formattedRawValue: String {
        String(format: "%.1f", rawValue)
    }

    var formattedContribution: String {
        String(format: "%.0f pts", contribution)
    }
}

// MARK: - Confidence Level

enum Confidence: String, Codable, CaseIterable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var description: String {
        switch self {
        case .low: return "Limited data available"
        case .medium: return "Some data gaps"
        case .high: return "Sufficient data quality"
        }
    }

    var icon: String {
        switch self {
        case .low: return "exclamationmark.circle"
        case .medium: return "checkmark.circle"
        case .high: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Data Quality Indicator

struct DataQualityIndicator: Codable, Sendable {
    let heartRateCompleteness: Double  // 0-1
    let hrvCompleteness: Double  // 0-1
    let sleepCompleteness: Double  // 0-1
    let activityCompleteness: Double  // 0-1

    var overallCompleteness: Double {
        (heartRateCompleteness + hrvCompleteness + sleepCompleteness + activityCompleteness) / 4.0
    }

    var overallQuality: DataQuality {
        switch overallCompleteness {
        case 0..<0.5: return .poor
        case 0.5..<0.75: return .fair
        case 0.75..<0.9: return .good
        default: return .excellent
        }
    }

    var hasGaps: Bool {
        overallCompleteness < 0.9
    }

    var gapDescriptions: [String] {
        var gaps: [String] = []
        if heartRateCompleteness < 0.5 { gaps.append("Heart rate data sparse") }
        if hrvCompleteness < 0.5 { gaps.append("HRV data limited") }
        if sleepCompleteness < 0.5 { gaps.append("Sleep data incomplete") }
        if activityCompleteness < 0.5 { gaps.append("Activity data missing") }
        return gaps
    }
}

enum DataQuality: String, Codable, Sendable {
    case poor = "Poor"
    case fair = "Fair"
    case good = "Good"
    case excellent = "Excellent"
}

// MARK: - SwiftData Persistent Model

@Model
final class DailyMetricsRecord {
    @Attribute(.unique) var date: Date
    var metricsJSON: Data

    init(date: Date, metricsJSON: Data) {
        self.date = date
        self.metricsJSON = metricsJSON
    }

    @MainActor
    convenience init(date: Date, metrics: DailyMetrics) throws {
        let data = try JSONEncoder().encode(metrics)
        self.init(date: date, metricsJSON: data)
    }

    nonisolated func getMetrics() throws -> DailyMetrics {
        try JSONDecoder().decode(DailyMetrics.self, from: metricsJSON)
    }
}
