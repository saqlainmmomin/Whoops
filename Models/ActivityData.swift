import Foundation

// MARK: - Daily Activity Summary

struct DailyActivitySummary: Codable {
    let date: Date
    let steps: Int
    let distance: Double  // km
    let activeEnergy: Double  // kcal
    let basalEnergy: Double  // kcal

    var totalEnergy: Double {
        activeEnergy + basalEnergy
    }

    // Steps goal progress (assuming 10k steps goal)
    var stepsGoalProgress: Double {
        Double(steps) / 10000.0
    }

    // Activity intensity based on active energy ratio
    var activityIntensity: ActivityIntensity {
        let activeRatio = activeEnergy / max(totalEnergy, 1)
        switch activeRatio {
        case ..<0.15: return .sedentary
        case 0.15..<0.25: return .light
        case 0.25..<0.35: return .moderate
        case 0.35..<0.45: return .active
        default: return .veryActive
        }
    }

    var formattedDistance: String {
        String(format: "%.1f km", distance)
    }

    var formattedActiveEnergy: String {
        String(format: "%.0f kcal", activeEnergy)
    }
}

// MARK: - Activity Intensity

enum ActivityIntensity: String, Codable {
    case sedentary = "Sedentary"
    case light = "Light"
    case moderate = "Moderate"
    case active = "Active"
    case veryActive = "Very Active"

    var description: String {
        switch self {
        case .sedentary: return "Minimal activity"
        case .light: return "Light activity"
        case .moderate: return "Moderate activity"
        case .active: return "Active day"
        case .veryActive: return "Very active day"
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary: return 0.2
        case .light: return 0.5
        case .moderate: return 0.75
        case .active: return 1.0
        case .veryActive: return 1.25
        }
    }
}

// MARK: - Weekly Activity Stats

struct WeeklyActivityStats: Codable {
    let weekStartDate: Date
    let dailySummaries: [DailyActivitySummary]

    var totalSteps: Int {
        dailySummaries.reduce(0) { $0 + $1.steps }
    }

    var averageDailySteps: Int {
        guard !dailySummaries.isEmpty else { return 0 }
        return totalSteps / dailySummaries.count
    }

    var totalDistance: Double {
        dailySummaries.reduce(0) { $0 + $1.distance }
    }

    var averageDailyDistance: Double {
        guard !dailySummaries.isEmpty else { return 0 }
        return totalDistance / Double(dailySummaries.count)
    }

    var totalActiveEnergy: Double {
        dailySummaries.reduce(0) { $0 + $1.activeEnergy }
    }

    var averageDailyActiveEnergy: Double {
        guard !dailySummaries.isEmpty else { return 0 }
        return totalActiveEnergy / Double(dailySummaries.count)
    }

    var mostActiveDay: DailyActivitySummary? {
        dailySummaries.max(by: { $0.activeEnergy < $1.activeEnergy })
    }

    var leastActiveDay: DailyActivitySummary? {
        dailySummaries.min(by: { $0.activeEnergy < $1.activeEnergy })
    }

    // Days meeting 10k step goal
    var daysMetStepGoal: Int {
        dailySummaries.filter { $0.steps >= 10000 }.count
    }
}

// MARK: - Activity Load (for Strain calculation)

struct ActivityLoad: Codable {
    let date: Date
    let totalActiveMinutes: Int  // Estimated from energy and intensity
    let energyBurned: Double
    let stepsContribution: Double  // Normalized steps contribution
    let workoutContribution: Double  // From workout duration and intensity

    var totalLoad: Double {
        stepsContribution + workoutContribution + (energyBurned / 500.0)
    }

    // Acute load = 7-day exponentially weighted moving average
    static func calculateAcuteLoad(from loads: [ActivityLoad]) -> Double {
        guard !loads.isEmpty else { return 0 }

        // Use exponential decay (more recent = higher weight)
        let decayFactor = 0.85
        var weightedSum: Double = 0
        var weightSum: Double = 0

        for (index, load) in loads.suffix(7).enumerated() {
            let weight = pow(decayFactor, Double(6 - index))
            weightedSum += load.totalLoad * weight
            weightSum += weight
        }

        return weightSum > 0 ? weightedSum / weightSum : 0
    }

    // Chronic load = 28-day exponentially weighted moving average
    static func calculateChronicLoad(from loads: [ActivityLoad]) -> Double {
        guard !loads.isEmpty else { return 0 }

        let decayFactor = 0.95
        var weightedSum: Double = 0
        var weightSum: Double = 0

        for (index, load) in loads.suffix(28).enumerated() {
            let weight = pow(decayFactor, Double(27 - index))
            weightedSum += load.totalLoad * weight
            weightSum += weight
        }

        return weightSum > 0 ? weightedSum / weightSum : 0
    }
}
