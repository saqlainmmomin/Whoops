import Foundation
import HealthKit
import Combine

// MARK: - SpO2 Sample

struct SpO2Sample: Identifiable, Codable {
    var id: Date { timestamp }

    let timestamp: Date
    let percentage: Double  // 0-100
    let source: DataSource

    var roundedPercentage: Int { Int(percentage.rounded()) }
}

// MARK: - HealthKit Pipeline Queries
// Adds SpO2, anchored object queries, and statistics collection queries
// All scoped to Apple Watch Series 5 hardware constraints

extension HealthKitManager {

    // MARK: - SpO2 (Foreground Spot-Check Only on Series 5)

    /// Fetch SpO2 samples for a date range.
    /// On Apple Watch Series 5, SpO2 is foreground-only — no background delivery.
    func fetchSpO2Samples(for dateRange: DateInterval) async throws -> [SpO2Sample] {
        guard HealthKitPermissions.isSeries5Supported(.oxygenSaturation),
              let spo2Type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
            throw HealthKitError.typeUnavailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: dateRange.start,
            end: dateRange.end,
            options: .strictStartDate
        )

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: spo2Type,
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

        return samples.map { sample in
            SpO2Sample(
                timestamp: sample.startDate,
                percentage: sample.quantity.doubleValue(for: .percent()) * 100,
                source: DataSource(
                    name: sample.sourceRevision.source.name,
                    bundleIdentifier: sample.sourceRevision.source.bundleIdentifier,
                    version: sample.sourceRevision.version ?? "unknown"
                )
            )
        }
    }

    /// Fetch the most recent SpO2 reading.
    func fetchLatestSpO2() async throws -> SpO2Sample? {
        guard HealthKitPermissions.isSeries5Supported(.oxygenSaturation),
              let spo2Type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
            return nil
        }

        let sample = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKQuantitySample?, Error>) in
            let query = HKSampleQuery(
                sampleType: spo2Type,
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

        guard let sample = sample else { return nil }
        return SpO2Sample(
            timestamp: sample.startDate,
            percentage: sample.quantity.doubleValue(for: .percent()) * 100,
            source: DataSource(
                name: sample.sourceRevision.source.name,
                bundleIdentifier: sample.sourceRevision.source.bundleIdentifier,
                version: sample.sourceRevision.version ?? "unknown"
            )
        )
    }

    // MARK: - Statistics Collection Queries

    /// Build an HKStatisticsCollectionQuery for hourly heart rate averages over a date range.
    func fetchHourlyHeartRateStatistics(
        for dateRange: DateInterval
    ) async throws -> [(date: Date, avgBPM: Double)] {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.typeUnavailable
        }

        let calendar = Calendar.current
        var anchorComponents = calendar.dateComponents([.day, .month, .year], from: dateRange.start)
        anchorComponents.hour = 0
        let anchorDate = calendar.date(from: anchorComponents)!

        let predicate = HKQuery.predicateForSamples(
            withStart: dateRange.start,
            end: dateRange.end,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: hrType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage,
                anchorDate: anchorDate,
                intervalComponents: DateComponents(hour: 1)
            )

            query.initialResultsHandler = { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                var hourlyData: [(date: Date, avgBPM: Double)] = []
                results?.enumerateStatistics(from: dateRange.start, to: dateRange.end) { statistics, _ in
                    if let avg = statistics.averageQuantity() {
                        let bpm = avg.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                        hourlyData.append((date: statistics.startDate, avgBPM: bpm))
                    }
                }
                continuation.resume(returning: hourlyData)
            }

            healthStore.execute(query)
        }
    }

    /// Build an HKStatisticsCollectionQuery for daily active energy totals.
    func fetchDailyActiveEnergyStatistics(
        for dateRange: DateInterval
    ) async throws -> [(date: Date, kcal: Double)] {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.typeUnavailable
        }

        let calendar = Calendar.current
        let anchorDate = calendar.startOfDay(for: dateRange.start)

        let predicate = HKQuery.predicateForSamples(
            withStart: dateRange.start,
            end: dateRange.end,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchorDate,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                var dailyData: [(date: Date, kcal: Double)] = []
                results?.enumerateStatistics(from: dateRange.start, to: dateRange.end) { statistics, _ in
                    if let sum = statistics.sumQuantity() {
                        let kcal = sum.doubleValue(for: .kilocalorie())
                        dailyData.append((date: statistics.startDate, kcal: kcal))
                    }
                }
                continuation.resume(returning: dailyData)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Anchored Object Queries (Incremental Updates)

    /// Fetch new heart rate samples since the last anchor.
    /// Returns updated samples and a new anchor for the next query.
    func fetchHeartRateUpdates(
        since anchor: HKQueryAnchor?
    ) async throws -> (samples: [HeartRateSample], newAnchor: HKQueryAnchor?) {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.typeUnavailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKAnchoredObjectQuery(
                type: hrType,
                predicate: nil,
                anchor: anchor,
                limit: HKObjectQueryNoLimit
            ) { _, added, _, newAnchor, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let samples = (added as? [HKQuantitySample] ?? []).map { sample in
                    HeartRateSample(
                        timestamp: sample.startDate,
                        bpm: sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())),
                        source: DataSource(
                            name: sample.sourceRevision.source.name,
                            bundleIdentifier: sample.sourceRevision.source.bundleIdentifier,
                            version: sample.sourceRevision.version ?? "unknown"
                        )
                    )
                }
                continuation.resume(returning: (samples: samples, newAnchor: newAnchor))
            }
            healthStore.execute(query)
        }
    }

    /// Fetch new HRV samples since the last anchor.
    func fetchHRVUpdates(
        since anchor: HKQueryAnchor?
    ) async throws -> (samples: [HRVSample], newAnchor: HKQueryAnchor?) {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            throw HealthKitError.typeUnavailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKAnchoredObjectQuery(
                type: hrvType,
                predicate: nil,
                anchor: anchor,
                limit: HKObjectQueryNoLimit
            ) { _, added, _, newAnchor, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let samples = (added as? [HKQuantitySample] ?? []).map { sample in
                    HRVSample(
                        timestamp: sample.startDate,
                        sdnn: sample.quantity.doubleValue(for: .secondUnit(with: .milli)),
                        source: DataSource(
                            name: sample.sourceRevision.source.name,
                            bundleIdentifier: sample.sourceRevision.source.bundleIdentifier,
                            version: sample.sourceRevision.version ?? "unknown"
                        )
                    )
                }
                continuation.resume(returning: (samples: samples, newAnchor: newAnchor))
            }
            healthStore.execute(query)
        }
    }

    /// Fetch new sleep samples since the last anchor.
    func fetchSleepUpdates(
        since anchor: HKQueryAnchor?
    ) async throws -> (samples: [SleepSample], newAnchor: HKQueryAnchor?) {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.typeUnavailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKAnchoredObjectQuery(
                type: sleepType,
                predicate: nil,
                anchor: anchor,
                limit: HKObjectQueryNoLimit
            ) { _, added, _, newAnchor, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let samples = HKDataMappers.mapSleepSamples(added as? [HKCategorySample] ?? [])
                continuation.resume(returning: (samples: samples, newAnchor: newAnchor))
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Background Delivery Registration (Series 5 Eligible Types Only)

    /// Register for background delivery on Series 5-eligible types.
    /// SpO2 is excluded (foreground-only on S5).
    func registerBackgroundDelivery() async {
        for identifier in HealthKitPermissions.backgroundDeliveryTypes {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }

            do {
                try await healthStore.enableBackgroundDelivery(for: type, frequency: .hourly)
            } catch {
                print("Background delivery failed for \(identifier.rawValue): \(error.localizedDescription)")
            }
        }

        // Sleep analysis — background delivery
        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            do {
                try await healthStore.enableBackgroundDelivery(for: sleepType, frequency: .hourly)
            } catch {
                print("Background delivery failed for sleep: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Enhanced Authorization Using Permissions Manifest

    /// Request authorization using the centralized Series 5 permission manifest.
    func requestSeries5Authorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .denied
            throw HealthKitError.typeUnavailable
        }

        let filteredTypes = HealthKitPermissions.filterToSeries5(HealthKitPermissions.readTypes)
        try await healthStore.requestAuthorization(toShare: [], read: filteredTypes)
        await checkAuthorizationStatus()
    }
}
