import Foundation

struct DailyAssessment: Sendable {
    let date: Date
    let metrics: DailyMetrics
    let sevenDayBaseline: Baseline
    let twentyEightDayBaseline: Baseline
    let recovery: RecoveryAssessment?
    let strainTarget: StrainTargetAssessment?
    let sleepGuidance: SleepGuidanceAssessment?
    let primaryInsight: String
    let recommendedAction: String
    let primaryBlocker: String?
    let confidence: Confidence
    let warnings: [String]

    var headline: String {
        if let recovery {
            switch recovery.score {
            case 80...100:
                return "Recovered and ready to push"
            case 60..<80:
                return "Recovered enough for a normal day"
            case 40..<60:
                return "Mixed recovery today"
            default:
                return "Recovery is suppressed today"
            }
        }

        if confidence == .low {
            return "Limited data, keep today conservative"
        }

        return "Assessment incomplete"
    }
}

struct RecoveryAssessment: Sendable {
    let score: Int
    let confidence: Confidence
    let explanation: [String]
    let recommendationImpact: String
}

struct StrainTargetAssessment: Sendable {
    let range: ClosedRange<Double>
    let recommendedTarget: Double
    let dayType: String
    let confidence: Confidence
    let explanation: [String]
    let recommendation: String
}

struct SleepGuidanceAssessment: Sendable {
    let sleepNeedHours: Double
    let additionalNeedHours: Double
    let recommendedBedtime: Date?
    let bedtimeConfidence: Confidence
    let explanation: [String]
    let recommendation: String
}

struct DailyAssessmentLoadResult: Sendable {
    let assessment: DailyAssessment
    let weeklyMetrics: [DailyMetrics]
}

struct DailyAssessmentHistoryLoadResult: Sendable {
    let assessments: [DailyAssessment]

    var dailyMetrics: [DailyMetrics] {
        assessments.map(\.metrics)
    }

    var latestAssessment: DailyAssessment? {
        assessments.last
    }
}
