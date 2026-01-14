import Foundation

// MARK: - Workout Activity Type

enum WorkoutActivityType: String, CaseIterable, Codable {
    case running = "Running"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case walking = "Walking"
    case hiking = "Hiking"
    case yoga = "Yoga"
    case strength = "Strength Training"
    case hiit = "HIIT"
    case rowing = "Rowing"
    case elliptical = "Elliptical"
    case crossTraining = "Cross Training"
    case other = "Other"

    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .walking: return "figure.walk"
        case .hiking: return "figure.hiking"
        case .yoga: return "figure.yoga"
        case .strength: return "dumbbell.fill"
        case .hiit: return "flame.fill"
        case .rowing: return "figure.rower"
        case .elliptical: return "figure.elliptical"
        case .crossTraining: return "figure.cross.training"
        case .other: return "figure.mixed.cardio"
        }
    }

    // Base strain multiplier by activity type
    var intensityMultiplier: Double {
        switch self {
        case .hiit: return 1.5
        case .running: return 1.3
        case .cycling: return 1.2
        case .swimming: return 1.25
        case .rowing: return 1.2
        case .crossTraining: return 1.2
        case .strength: return 1.0
        case .hiking: return 1.0
        case .elliptical: return 1.1
        case .walking: return 0.7
        case .yoga: return 0.5
        case .other: return 1.0
        }
    }
}

// MARK: - Workout Session

struct WorkoutSession: Identifiable, Codable {
    let id: UUID
    let activityType: WorkoutActivityType
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let totalEnergyBurned: Double?  // kcal
    let totalDistance: Double?  // km
    let averageHeartRate: Double?
    let maxHeartRate: Double?
    let source: DataSource

    var durationMinutes: Int {
        Int(duration / 60)
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var pace: Double? {
        guard let distance = totalDistance, distance > 0, duration > 0 else { return nil }
        return duration / 60 / distance  // min/km
    }

    var formattedPace: String? {
        guard let pace = pace else { return nil }
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d /km", minutes, seconds)
    }
}

// MARK: - Daily Workout Summary

struct DailyWorkoutSummary: Codable {
    let date: Date
    let workouts: [WorkoutSession]

    var totalWorkouts: Int {
        workouts.count
    }

    var totalDurationMinutes: Int {
        workouts.reduce(0) { $0 + $1.durationMinutes }
    }

    var totalEnergyBurned: Double {
        workouts.compactMap(\.totalEnergyBurned).reduce(0, +)
    }

    var totalDistance: Double {
        workouts.compactMap(\.totalDistance).reduce(0, +)
    }

    var averageHeartRate: Double? {
        let hrValues = workouts.compactMap(\.averageHeartRate)
        guard !hrValues.isEmpty else { return nil }
        return hrValues.reduce(0, +) / Double(hrValues.count)
    }

    var maxHeartRate: Double? {
        workouts.compactMap(\.maxHeartRate).max()
    }

    var primaryActivity: WorkoutActivityType? {
        // Return the activity type with the most duration
        var durationByType: [WorkoutActivityType: TimeInterval] = [:]
        for workout in workouts {
            durationByType[workout.activityType, default: 0] += workout.duration
        }
        return durationByType.max(by: { $0.value < $1.value })?.key
    }

    // Calculate total strain contribution
    var strainContribution: Double {
        workouts.reduce(0) { total, workout in
            let baseDuration = Double(workout.durationMinutes)
            let intensityFactor = workout.activityType.intensityMultiplier
            let hrFactor: Double = {
                guard let avgHR = workout.averageHeartRate else { return 1.0 }
                // Higher HR = more strain
                return min(avgHR / 120.0, 1.5)  // Cap at 1.5x
            }()
            return total + (baseDuration * intensityFactor * hrFactor)
        }
    }
}

// MARK: - Workout Load

struct WorkoutLoad: Codable {
    let date: Date
    let durationMinutes: Int
    let energyBurned: Double
    let averageIntensity: Double  // 0-1 scale
    let zoneDistribution: ZoneTimeDistribution?

    // Training Impulse (TRIMP) - simplified version
    var trimp: Double {
        Double(durationMinutes) * averageIntensity
    }
}

// MARK: - Weekly Workout Stats

struct WeeklyWorkoutStats: Codable {
    let weekStartDate: Date
    let workouts: [WorkoutSession]

    var totalWorkouts: Int { workouts.count }
    var totalDurationMinutes: Int { workouts.reduce(0) { $0 + $1.durationMinutes } }
    var totalEnergyBurned: Double { workouts.compactMap(\.totalEnergyBurned).reduce(0, +) }
    var totalDistance: Double { workouts.compactMap(\.totalDistance).reduce(0, +) }

    var averageWorkoutDuration: Int {
        guard totalWorkouts > 0 else { return 0 }
        return totalDurationMinutes / totalWorkouts
    }

    var workoutsByType: [WorkoutActivityType: Int] {
        var counts: [WorkoutActivityType: Int] = [:]
        for workout in workouts {
            counts[workout.activityType, default: 0] += 1
        }
        return counts
    }

    var mostFrequentActivity: WorkoutActivityType? {
        workoutsByType.max(by: { $0.value < $1.value })?.key
    }
}
