import Foundation
import HealthKit
import Combine
import SwiftData

enum HealthKitAuthorizationStatus {
    case notDetermined
    case authorized
    case denied
}

@MainActor
class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private let queryBuilders = HKQueryBuilders()

    @Published var authorizationStatus: HealthKitAuthorizationStatus = .notDetermined
    @Published var isHealthKitAvailable: Bool = HKHealthStore.isHealthDataAvailable()

    // Data types we need to read
    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()

        // Heart Rate types
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let restingHR = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(restingHR)
        }
        if let hrv = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            types.insert(hrv)
        }

        // Sleep types
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }

        // Activity types
        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            types.insert(steps)
        }
        if let distance = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            types.insert(distance)
        }
        if let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }
        if let basalEnergy = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) {
            types.insert(basalEnergy)
        }

        // Respiratory rate
        if let respiratoryRate = HKQuantityType.quantityType(forIdentifier: .respiratoryRate) {
            types.insert(respiratoryRate)
        }

        // Body temperature (optional)
        if let bodyTemp = HKQuantityType.quantityType(forIdentifier: .bodyTemperature) {
            types.insert(bodyTemp)
        }

        // VO2 Max
        if let vo2Max = HKQuantityType.quantityType(forIdentifier: .vo2Max) {
            types.insert(vo2Max)
        }

        // Workouts
        types.insert(HKWorkoutType.workoutType())

        return types
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        guard isHealthKitAvailable else {
            authorizationStatus = .denied
            return
        }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            await checkAuthorizationStatus()
        } catch {
            print("HealthKit authorization error: \(error.localizedDescription)")
            authorizationStatus = .denied
        }
    }

    private func checkAuthorizationStatus() async {
        // Check if we have read access to at least heart rate (our primary data type)
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            authorizationStatus = .denied
            return
        }

        let status = healthStore.authorizationStatus(for: heartRateType)
        switch status {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .sharingDenied:
            // For read-only, we can't determine denial - try a sample query
            authorizationStatus = .authorized
        case .sharingAuthorized:
            authorizationStatus = .authorized
        @unknown default:
            authorizationStatus = .notDetermined
        }
    }

    // MARK: - Heart Rate Data

    func fetchHeartRateSamples(for dateRange: DateInterval) async throws -> [HeartRateSample] {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.typeUnavailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: dateRange.start,
            end: dateRange.end,
            options: .strictStartDate
        )

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
            }
            healthStore.execute(query)
        }

        return HKDataMappers.mapHeartRateSamples(samples)
    }

    func fetchRestingHeartRate(for dateRange: DateInterval) async throws -> [RestingHeartRateSample] {
        guard let rhrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            throw HealthKitError.typeUnavailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: dateRange.start,
            end: dateRange.end,
            options: .strictStartDate
        )

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: rhrType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
            }
            healthStore.execute(query)
        }

        return HKDataMappers.mapRestingHeartRateSamples(samples)
    }

    func fetchHRVSamples(for dateRange: DateInterval) async throws -> [HRVSample] {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            throw HealthKitError.typeUnavailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: dateRange.start,
            end: dateRange.end,
            options: .strictStartDate
        )

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
            }
            healthStore.execute(query)
        }

        return HKDataMappers.mapHRVSamples(samples)
    }

    // MARK: - Sleep Data

    func fetchSleepSamples(for dateRange: DateInterval) async throws -> [SleepSample] {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.typeUnavailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: dateRange.start,
            end: dateRange.end,
            options: .strictStartDate
        )

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKCategorySample] ?? [])
            }
            healthStore.execute(query)
        }

        return HKDataMappers.mapSleepSamples(samples)
    }

    // MARK: - Workout Data

    func fetchWorkouts(for dateRange: DateInterval) async throws -> [WorkoutSession] {
        let predicate = HKQuery.predicateForSamples(
            withStart: dateRange.start,
            end: dateRange.end,
            options: .strictStartDate
        )

        let workouts = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkout], Error>) in
            let query = HKSampleQuery(
                sampleType: HKWorkoutType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKWorkout] ?? [])
            }
            healthStore.execute(query)
        }

        return HKDataMappers.mapWorkouts(workouts)
    }

    // MARK: - Activity Data

    func fetchSteps(for dateRange: DateInterval) async throws -> Int {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.typeUnavailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: dateRange.start,
            end: dateRange.end,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let steps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            healthStore.execute(query)
        }
    }

    func fetchActiveEnergy(for dateRange: DateInterval) async throws -> Double {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.typeUnavailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: dateRange.start,
            end: dateRange.end,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let energy = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: energy)
            }
            healthStore.execute(query)
        }
    }

    func fetchBasalEnergy(for dateRange: DateInterval) async throws -> Double {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) else {
            throw HealthKitError.typeUnavailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: dateRange.start,
            end: dateRange.end,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let energy = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: energy)
            }
            healthStore.execute(query)
        }
    }

    func fetchDistance(for dateRange: DateInterval) async throws -> Double {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            throw HealthKitError.typeUnavailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: dateRange.start,
            end: dateRange.end,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let distance = statistics?.sumQuantity()?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0
                continuation.resume(returning: distance)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Respiratory Rate

    func fetchRespiratoryRate(for dateRange: DateInterval) async throws -> [RespiratoryRateSample] {
        guard let rrType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate) else {
            throw HealthKitError.typeUnavailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: dateRange.start,
            end: dateRange.end,
            options: .strictStartDate
        )

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: rrType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
            }
            healthStore.execute(query)
        }

        return HKDataMappers.mapRespiratoryRateSamples(samples)
    }

    // MARK: - VO2 Max

    func fetchVO2Max(for dateRange: DateInterval) async throws -> Double? {
        guard let vo2Type = HKQuantityType.quantityType(forIdentifier: .vo2Max) else {
            throw HealthKitError.typeUnavailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: dateRange.start,
            end: dateRange.end,
            options: .strictStartDate
        )

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: vo2Type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
            }
            healthStore.execute(query)
        }

        guard let sample = samples.first else { return nil }
        return sample.quantity.doubleValue(for: HKUnit(from: "ml/kg*min"))
    }

    // MARK: - User Characteristics

    func fetchUserCharacteristics(modelContext: ModelContext) async {
        // Fetch the user profile to update
        let descriptor = FetchDescriptor<UserProfile>(sortBy: [SortDescriptor(\.createdDate, order: .reverse)])
        guard let profile = try? modelContext.fetch(descriptor).first else {
            return
        }

        // Biological Sex
        if let biologicalSex = try? healthStore.biologicalSex().biologicalSex {
            switch biologicalSex {
            case .female:
                profile.biologicalSex = "Female"
            case .male:
                profile.biologicalSex = "Male"
            case .other:
                profile.biologicalSex = "Other"
            case .notSet:
                profile.biologicalSex = nil
            @unknown default:
                profile.biologicalSex = nil
            }
        }

        // Date of Birth / Age
        if let dateOfBirthComponents = try? healthStore.dateOfBirthComponents(),
           let dateOfBirth = Calendar.current.date(from: dateOfBirthComponents) {
            let ageComponents = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date())
            profile.age = ageComponents.year
        }

        // Height (most recent sample)
        if let heightType = HKQuantityType.quantityType(forIdentifier: .height) {
            let heightSample = try? await fetchMostRecentSample(for: heightType)
            if let height = heightSample?.quantity.doubleValue(for: .meterUnit(with: .centi)) {
                profile.heightCM = height
            }
        }

        // Weight (most recent sample)
        if let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            let weightSample = try? await fetchMostRecentSample(for: weightType)
            if let weight = weightSample?.quantity.doubleValue(for: .gramUnit(with: .kilo)) {
                profile.weightKG = weight
            }
        }

        try? modelContext.save()
    }

    private func fetchMostRecentSample(for quantityType: HKQuantityType) async throws -> HKQuantitySample? {
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples?.first as? HKQuantitySample)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Composite Fetch

    func fetchDailyData(for date: Date) async throws -> RawDailyHealthData {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let dayRange = DateInterval(start: startOfDay, end: endOfDay)

        // Fetch all data in parallel
        async let heartRateSamples = fetchHeartRateSamples(for: dayRange)
        async let restingHRSamples = fetchRestingHeartRate(for: dayRange)
        async let hrvSamples = fetchHRVSamples(for: dayRange)
        async let sleepSamples = fetchSleepSamples(for: dayRange)
        async let workouts = fetchWorkouts(for: dayRange)
        async let steps = fetchSteps(for: dayRange)
        async let activeEnergy = fetchActiveEnergy(for: dayRange)
        async let basalEnergy = fetchBasalEnergy(for: dayRange)
        async let distance = fetchDistance(for: dayRange)
        async let respiratoryRate = fetchRespiratoryRate(for: dayRange)

        return try await RawDailyHealthData(
            date: date,
            heartRateSamples: heartRateSamples,
            restingHeartRateSamples: restingHRSamples,
            hrvSamples: hrvSamples,
            sleepSamples: sleepSamples,
            workouts: workouts,
            steps: steps,
            activeEnergy: activeEnergy,
            basalEnergy: basalEnergy,
            distance: distance,
            respiratoryRateSamples: respiratoryRate
        )
    }

    func fetchDataRange(from startDate: Date, to endDate: Date) async throws -> [RawDailyHealthData] {
        var dailyData: [RawDailyHealthData] = []
        var currentDate = startDate

        while currentDate <= endDate {
            let data = try await fetchDailyData(for: currentDate)
            dailyData.append(data)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return dailyData
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case typeUnavailable
    case queryFailed(String)
    case noData

    var errorDescription: String? {
        switch self {
        case .typeUnavailable:
            return "Health data type is not available on this device"
        case .queryFailed(let reason):
            return "Failed to query health data: \(reason)"
        case .noData:
            return "No health data available for the requested period"
        }
    }
}

// MARK: - Raw Data Container

struct RawDailyHealthData {
    let date: Date
    let heartRateSamples: [HeartRateSample]
    let restingHeartRateSamples: [RestingHeartRateSample]
    let hrvSamples: [HRVSample]
    let sleepSamples: [SleepSample]
    let workouts: [WorkoutSession]
    let steps: Int
    let activeEnergy: Double
    let basalEnergy: Double
    let distance: Double
    let respiratoryRateSamples: [RespiratoryRateSample]
}
