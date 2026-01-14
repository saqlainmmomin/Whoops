import Foundation
import SwiftData

// MARK: - Goal Model

@Model
final class Goal {
    var id: UUID
    var metricType: String  // "sleep", "hrv", "recovery", "strain", "rhr", "steps"
    var targetValue: Double
    var comparison: String  // ">=", "<=", "==", "range"
    var rangeMax: Double?   // For range comparison
    var unit: String
    var name: String
    var createdDate: Date
    var isActive: Bool

    // Streak tracking
    var currentStreak: Int
    var longestStreak: Int
    var lastAchievedDate: Date?
    var totalAchievements: Int

    init(
        metricType: String,
        targetValue: Double,
        comparison: String = ">=",
        rangeMax: Double? = nil,
        unit: String,
        name: String
    ) {
        self.id = UUID()
        self.metricType = metricType
        self.targetValue = targetValue
        self.comparison = comparison
        self.rangeMax = rangeMax
        self.unit = unit
        self.name = name
        self.createdDate = Date()
        self.isActive = true
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastAchievedDate = nil
        self.totalAchievements = 0
    }

    // Check if a value meets the goal
    func isAchieved(with value: Double) -> Bool {
        switch comparison {
        case ">=":
            return value >= targetValue
        case "<=":
            return value <= targetValue
        case "==":
            return abs(value - targetValue) < 0.1
        case "range":
            guard let max = rangeMax else { return false }
            return value >= targetValue && value <= max
        default:
            return false
        }
    }

    // Update streak based on achievement
    func recordAchievement(on date: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        if let lastDate = lastAchievedDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDiff == 1 {
                // Consecutive day
                currentStreak += 1
            } else if daysDiff > 1 {
                // Streak broken
                currentStreak = 1
            }
            // daysDiff == 0 means same day, don't increment
        } else {
            currentStreak = 1
        }

        longestStreak = max(longestStreak, currentStreak)
        lastAchievedDate = date
        totalAchievements += 1
    }

    func recordMiss(on date: Date) {
        currentStreak = 0
    }

    // Display helpers
    var targetDescription: String {
        switch comparison {
        case ">=":
            return "\(comparison) \(formattedTarget) \(unit)"
        case "<=":
            return "\(comparison) \(formattedTarget) \(unit)"
        case "range":
            guard let max = rangeMax else { return "\(formattedTarget) \(unit)" }
            return "\(formattedTarget) - \(Int(max)) \(unit)"
        default:
            return "\(formattedTarget) \(unit)"
        }
    }

    var formattedTarget: String {
        if targetValue == Double(Int(targetValue)) {
            return "\(Int(targetValue))"
        }
        return String(format: "%.1f", targetValue)
    }

    var streakEmoji: String {
        switch currentStreak {
        case 0: return ""
        case 1...2: return ""
        case 3...6: return ""
        case 7...13: return ""
        case 14...29: return ""
        default: return ""
        }
    }
}

// MARK: - Preset Goals

extension Goal {
    static func sleepGoal(hours: Double = 7) -> Goal {
        Goal(
            metricType: "sleep",
            targetValue: hours,
            comparison: ">=",
            unit: "hrs",
            name: "Sleep \(Int(hours))+ hours"
        )
    }

    static func hrvGoal(target: Double = 40) -> Goal {
        Goal(
            metricType: "hrv",
            targetValue: target,
            comparison: ">=",
            unit: "ms",
            name: "HRV above \(Int(target))"
        )
    }

    static func recoveryGoal(target: Double = 60) -> Goal {
        Goal(
            metricType: "recovery",
            targetValue: target,
            comparison: ">=",
            unit: "%",
            name: "Recovery \(Int(target))%+"
        )
    }

    static func strainBalanceGoal(min: Double = 40, max: Double = 60) -> Goal {
        Goal(
            metricType: "strain",
            targetValue: min,
            comparison: "range",
            rangeMax: max,
            unit: "",
            name: "Balanced strain (\(Int(min))-\(Int(max)))"
        )
    }

    static func stepsGoal(target: Double = 10000) -> Goal {
        Goal(
            metricType: "steps",
            targetValue: target,
            comparison: ">=",
            unit: "steps",
            name: "\(Int(target/1000))K steps daily"
        )
    }
}
