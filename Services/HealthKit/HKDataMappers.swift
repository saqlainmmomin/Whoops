import Foundation
import HealthKit

struct HKDataMappers {

    // MARK: - Heart Rate Mapping

    static func mapHeartRateSamples(_ samples: [HKQuantitySample]) -> [HeartRateSample] {
        samples.map { sample in
            HeartRateSample(
                timestamp: sample.startDate,
                bpm: sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())),
                source: mapSource(sample.sourceRevision)
            )
        }
    }

    static func mapRestingHeartRateSamples(_ samples: [HKQuantitySample]) -> [RestingHeartRateSample] {
        samples.map { sample in
            RestingHeartRateSample(
                date: sample.startDate,
                bpm: sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())),
                source: mapSource(sample.sourceRevision)
            )
        }
    }

    // MARK: - HRV Mapping

    static func mapHRVSamples(_ samples: [HKQuantitySample]) -> [HRVSample] {
        samples.map { sample in
            HRVSample(
                timestamp: sample.startDate,
                sdnn: sample.quantity.doubleValue(for: .secondUnit(with: .milli)),
                source: mapSource(sample.sourceRevision)
            )
        }
    }

    // MARK: - Sleep Mapping

    static func mapSleepSamples(_ samples: [HKCategorySample]) -> [SleepSample] {
        samples.compactMap { sample in
            guard let stage = mapSleepStage(sample.value) else { return nil }

            return SleepSample(
                startDate: sample.startDate,
                endDate: sample.endDate,
                stage: stage,
                source: mapSource(sample.sourceRevision)
            )
        }
    }

    private static func mapSleepStage(_ value: Int) -> SleepStage? {
        if #available(iOS 16.0, *) {
            switch HKCategoryValueSleepAnalysis(rawValue: value) {
            case .awake:
                return .awake
            case .asleepCore:
                return .core
            case .asleepDeep:
                return .deep
            case .asleepREM:
                return .rem
            case .asleepUnspecified, .asleep:
                return .unspecified
            case .inBed:
                return .inBed
            default:
                return nil
            }
        } else {
            switch HKCategoryValueSleepAnalysis(rawValue: value) {
            case .awake:
                return .awake
            case .asleep:
                return .unspecified
            case .inBed:
                return .inBed
            default:
                return nil
            }
        }
    }

    // MARK: - Workout Mapping

    static func mapWorkouts(_ workouts: [HKWorkout]) -> [WorkoutSession] {
        workouts.map { workout in
            WorkoutSession(
                id: workout.uuid,
                activityType: mapActivityType(workout.workoutActivityType),
                startDate: workout.startDate,
                endDate: workout.endDate,
                duration: workout.duration,
                totalEnergyBurned: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
                totalDistance: workout.totalDistance?.doubleValue(for: .meterUnit(with: .kilo)),
                averageHeartRate: extractAverageHeartRate(from: workout),
                maxHeartRate: extractMaxHeartRate(from: workout),
                source: mapSource(workout.sourceRevision)
            )
        }
    }

    private static func mapActivityType(_ type: HKWorkoutActivityType) -> WorkoutActivityType {
        switch type {
        case .running:
            return .running
        case .cycling:
            return .cycling
        case .swimming:
            return .swimming
        case .walking:
            return .walking
        case .hiking:
            return .hiking
        case .yoga:
            return .yoga
        case .functionalStrengthTraining, .traditionalStrengthTraining:
            return .strength
        case .highIntensityIntervalTraining:
            return .hiit
        case .rowing:
            return .rowing
        case .elliptical:
            return .elliptical
        case .crossTraining:
            return .crossTraining
        default:
            return .other
        }
    }

    private static func extractAverageHeartRate(from workout: HKWorkout) -> Double? {
        if #available(iOS 16.0, *) {
            if let stats = workout.statistics(for: HKQuantityType(.heartRate)) {
                return stats.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            }
        }
        return nil
    }

    private static func extractMaxHeartRate(from workout: HKWorkout) -> Double? {
        if #available(iOS 16.0, *) {
            if let stats = workout.statistics(for: HKQuantityType(.heartRate)) {
                return stats.maximumQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            }
        }
        return nil
    }

    // MARK: - Respiratory Rate Mapping

    static func mapRespiratoryRateSamples(_ samples: [HKQuantitySample]) -> [RespiratoryRateSample] {
        samples.map { sample in
            RespiratoryRateSample(
                timestamp: sample.startDate,
                breathsPerMinute: sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())),
                source: mapSource(sample.sourceRevision)
            )
        }
    }

    // MARK: - Source Mapping

    private static func mapSource(_ sourceRevision: HKSourceRevision) -> DataSource {
        DataSource(
            name: sourceRevision.source.name,
            bundleIdentifier: sourceRevision.source.bundleIdentifier,
            version: sourceRevision.version ?? "unknown"
        )
    }
}

// MARK: - Supporting Types

struct DataSource: Codable, Equatable {
    let name: String
    let bundleIdentifier: String
    let version: String

    var isAppleWatch: Bool {
        bundleIdentifier.contains("apple") && name.lowercased().contains("watch")
    }
}
