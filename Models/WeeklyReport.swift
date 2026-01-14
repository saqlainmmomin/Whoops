import Foundation
import SwiftData

// MARK: - Weekly Report Model

@Model
final class WeeklyReport {
    var id: UUID
    var weekStartDate: Date
    var weekEndDate: Date
    var generatedDate: Date

    // Summary stats
    var averageRecovery: Double
    var averageStrain: Double
    var averageHRV: Double
    var totalSleepHours: Double
    var totalWorkoutMinutes: Int
    var totalSteps: Int

    // Comparisons to previous week
    var recoveryChange: Double      // Percentage change
    var strainChange: Double
    var hrvChange: Double
    var sleepChange: Double

    // Goal achievements
    var goalsAchievedCount: Int
    var goalsAttemptedCount: Int

    // What worked / didn't work
    var positiveInsightsJSON: Data  // [String]
    var negativeInsightsJSON: Data  // [String]
    var recommendationsJSON: Data   // [String]

    // Best/Worst days
    var bestRecoveryDay: Date?
    var bestRecoveryScore: Int?
    var worstRecoveryDay: Date?
    var worstRecoveryScore: Int?

    init(
        weekStartDate: Date,
        weekEndDate: Date,
        averageRecovery: Double,
        averageStrain: Double,
        averageHRV: Double,
        totalSleepHours: Double,
        totalWorkoutMinutes: Int,
        totalSteps: Int,
        recoveryChange: Double,
        strainChange: Double,
        hrvChange: Double,
        sleepChange: Double,
        goalsAchievedCount: Int,
        goalsAttemptedCount: Int,
        positiveInsights: [String],
        negativeInsights: [String],
        recommendations: [String],
        bestRecoveryDay: Date? = nil,
        bestRecoveryScore: Int? = nil,
        worstRecoveryDay: Date? = nil,
        worstRecoveryScore: Int? = nil
    ) {
        self.id = UUID()
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.generatedDate = Date()
        self.averageRecovery = averageRecovery
        self.averageStrain = averageStrain
        self.averageHRV = averageHRV
        self.totalSleepHours = totalSleepHours
        self.totalWorkoutMinutes = totalWorkoutMinutes
        self.totalSteps = totalSteps
        self.recoveryChange = recoveryChange
        self.strainChange = strainChange
        self.hrvChange = hrvChange
        self.sleepChange = sleepChange
        self.goalsAchievedCount = goalsAchievedCount
        self.goalsAttemptedCount = goalsAttemptedCount
        self.positiveInsightsJSON = (try? JSONEncoder().encode(positiveInsights)) ?? Data()
        self.negativeInsightsJSON = (try? JSONEncoder().encode(negativeInsights)) ?? Data()
        self.recommendationsJSON = (try? JSONEncoder().encode(recommendations)) ?? Data()
        self.bestRecoveryDay = bestRecoveryDay
        self.bestRecoveryScore = bestRecoveryScore
        self.worstRecoveryDay = worstRecoveryDay
        self.worstRecoveryScore = worstRecoveryScore
    }

    // Computed properties for decoded arrays
    var positiveInsights: [String] {
        (try? JSONDecoder().decode([String].self, from: positiveInsightsJSON)) ?? []
    }

    var negativeInsights: [String] {
        (try? JSONDecoder().decode([String].self, from: negativeInsightsJSON)) ?? []
    }

    var recommendations: [String] {
        (try? JSONDecoder().decode([String].self, from: recommendationsJSON)) ?? []
    }

    // Display helpers
    var weekRangeDescription: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStartDate)) - \(formatter.string(from: weekEndDate))"
    }

    var recoveryGrade: String {
        switch averageRecovery {
        case 70...: return "A"
        case 55..<70: return "B"
        case 40..<55: return "C"
        case 25..<40: return "D"
        default: return "F"
        }
    }

    var goalCompletionPercentage: Double {
        guard goalsAttemptedCount > 0 else { return 0 }
        return Double(goalsAchievedCount) / Double(goalsAttemptedCount) * 100
    }

    var overallAssessment: String {
        if averageRecovery >= 70 && goalCompletionPercentage >= 70 {
            return "Excellent week! You're making great progress."
        } else if averageRecovery >= 55 && goalCompletionPercentage >= 50 {
            return "Good week with room for improvement."
        } else if averageRecovery >= 40 {
            return "Challenging week. Focus on recovery next week."
        } else {
            return "Recovery was low this week. Consider reducing strain."
        }
    }

    func changeDescription(for change: Double, metric: String, higherIsBetter: Bool = true) -> String {
        let improved = higherIsBetter ? change > 0 : change < 0
        let arrow = improved ? "" : ""
        let sign = change >= 0 ? "+" : ""
        return "\(arrow) \(sign)\(Int(change))% \(metric) vs last week"
    }
}
