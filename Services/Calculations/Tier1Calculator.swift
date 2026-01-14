import Foundation

/// Tier 1 Calculator: Factual Metrics (No Inference)
/// These are direct calculations from raw health data with no prediction or estimation.
struct Tier1Calculator {

    // MARK: - Heart Rate Metrics

    /// Calculate daily heart rate summary from raw samples
    static func calculateHeartRateSummary(
        heartRateSamples: [HeartRateSample],
        restingHRSamples: [RestingHeartRateSample],
        for date: Date
    ) -> DailyHeartRateSummary? {
        guard !heartRateSamples.isEmpty else { return nil }

        let bpmValues = heartRateSamples.map(\.bpm)

        return DailyHeartRateSummary(
            date: date,
            averageBPM: bpmValues.mean ?? 0,
            minBPM: bpmValues.min() ?? 0,
            maxBPM: bpmValues.max() ?? 0,
            restingBPM: restingHRSamples.last?.bpm,
            sampleCount: heartRateSamples.count
        )
    }

    /// Calculate daily HRV summary from raw samples
    static func calculateHRVSummary(
        hrvSamples: [HRVSample],
        sleepWindow: DateInterval,
        for date: Date
    ) -> DailyHRVSummary? {
        guard !hrvSamples.isEmpty else { return nil }

        let sdnnValues = hrvSamples.map(\.sdnn)

        // Filter for nighttime HRV (during sleep window)
        let nighttimeSamples = hrvSamples.filter { sample in
            sleepWindow.contains(sample.timestamp)
        }
        let nightlySDNN = nighttimeSamples.map(\.sdnn).mean

        return DailyHRVSummary(
            date: date,
            averageSDNN: sdnnValues.mean ?? 0,
            minSDNN: sdnnValues.min() ?? 0,
            maxSDNN: sdnnValues.max() ?? 0,
            nightlySDNN: nightlySDNN,
            sampleCount: hrvSamples.count
        )
    }

    // MARK: - Sleep Metrics

    /// Consolidate sleep samples into sessions and calculate summary
    static func calculateSleepSummary(
        sleepSamples: [SleepSample],
        for date: Date
    ) -> DailySleepSummary? {
        guard !sleepSamples.isEmpty else { return nil }

        // Sort samples by start date
        let sortedSamples = sleepSamples.sorted { $0.startDate < $1.startDate }

        // Group into sessions (gaps > 2 hours = new session)
        var sessions: [SleepSession] = []
        var currentSessionSamples: [SleepSample] = []
        var sessionStart: Date?

        for sample in sortedSamples {
            if let lastSample = currentSessionSamples.last {
                let gap = sample.startDate.timeIntervalSince(lastSample.endDate)

                if gap > 7200 { // 2 hours = new session
                    if !currentSessionSamples.isEmpty, let start = sessionStart {
                        let session = SleepSession(
                            id: UUID(),
                            startDate: start,
                            endDate: lastSample.endDate,
                            samples: currentSessionSamples
                        )
                        sessions.append(session)
                    }
                    currentSessionSamples = []
                    sessionStart = sample.startDate
                }
            } else {
                sessionStart = sample.startDate
            }
            currentSessionSamples.append(sample)
        }

        // Add final session
        if !currentSessionSamples.isEmpty, let start = sessionStart, let lastSample = currentSessionSamples.last {
            let session = SleepSession(
                id: UUID(),
                startDate: start,
                endDate: lastSample.endDate,
                samples: currentSessionSamples
            )
            sessions.append(session)
        }

        return DailySleepSummary(date: date, sessions: sessions)
    }

    /// Calculate sleep efficiency
    static func calculateSleepEfficiency(from session: SleepSession) -> Double {
        session.efficiency
    }

    /// Calculate sleep timing from session
    static func calculateSleepTiming(from session: SleepSession) -> SleepTiming {
        SleepTiming(bedtime: session.startDate, wakeTime: session.endDate)
    }

    // MARK: - Workout Metrics

    /// Calculate daily workout summary
    static func calculateWorkoutSummary(
        workouts: [WorkoutSession],
        for date: Date
    ) -> DailyWorkoutSummary {
        DailyWorkoutSummary(date: date, workouts: workouts)
    }

    /// Calculate HR recovery from workout
    static func calculateHRRecovery(
        workout: WorkoutSession,
        heartRateSamples: [HeartRateSample]
    ) -> HRRecoveryData? {
        guard let maxHR = workout.maxHeartRate else { return nil }

        // Find HR samples in the 3 minutes after workout
        let recoveryWindow = workout.endDate...workout.endDate.adding(minutes: 3)
        let recoverySamples = heartRateSamples.filter { recoveryWindow.contains($0.timestamp) }

        guard !recoverySamples.isEmpty else { return nil }

        // Find samples at 1, 2, and 3 minutes post-workout
        let hr1Min = findHRAtMinute(1, after: workout.endDate, in: recoverySamples)
        let hr2Min = findHRAtMinute(2, after: workout.endDate, in: recoverySamples)
        let hr3Min = findHRAtMinute(3, after: workout.endDate, in: recoverySamples)

        return HRRecoveryData(
            workoutEndTime: workout.endDate,
            peakHR: maxHR,
            hr1Min: hr1Min,
            hr2Min: hr2Min,
            hr3Min: hr3Min
        )
    }

    private static func findHRAtMinute(_ minute: Int, after date: Date, in samples: [HeartRateSample]) -> Double? {
        let targetTime = date.adding(minutes: minute)
        let tolerance: TimeInterval = 30 // 30 second tolerance

        let nearestSample = samples
            .filter { abs($0.timestamp.timeIntervalSince(targetTime)) <= tolerance }
            .min { abs($0.timestamp.timeIntervalSince(targetTime)) < abs($1.timestamp.timeIntervalSince(targetTime)) }

        return nearestSample?.bpm
    }

    // MARK: - Activity Metrics

    /// Calculate daily activity summary
    static func calculateActivitySummary(
        steps: Int,
        distance: Double,
        activeEnergy: Double,
        basalEnergy: Double,
        for date: Date
    ) -> DailyActivitySummary {
        DailyActivitySummary(
            date: date,
            steps: steps,
            distance: distance,
            activeEnergy: activeEnergy,
            basalEnergy: basalEnergy
        )
    }

    // MARK: - Zone Distribution

    /// Calculate time spent in each HR zone
    static func calculateZoneDistribution(
        heartRateSamples: [HeartRateSample],
        maxHeartRate: Double
    ) -> ZoneTimeDistribution {
        var zoneCounts: [HRZone: Int] = [:]

        for sample in heartRateSamples {
            let zone = HRZone.zone(for: sample.bpm, maxHeartRate: maxHeartRate)
            zoneCounts[zone, default: 0] += 1
        }

        // Assume ~1 minute per sample (Apple Watch typically samples every minute during activity)
        // Adjust based on actual sample density
        let sampleDensity = calculateSampleDensity(heartRateSamples)

        return ZoneTimeDistribution(
            zone1Minutes: Int(Double(zoneCounts[.zone1] ?? 0) * sampleDensity),
            zone2Minutes: Int(Double(zoneCounts[.zone2] ?? 0) * sampleDensity),
            zone3Minutes: Int(Double(zoneCounts[.zone3] ?? 0) * sampleDensity),
            zone4Minutes: Int(Double(zoneCounts[.zone4] ?? 0) * sampleDensity),
            zone5Minutes: Int(Double(zoneCounts[.zone5] ?? 0) * sampleDensity)
        )
    }

    private static func calculateSampleDensity(_ samples: [HeartRateSample]) -> Double {
        guard samples.count >= 2 else { return 1.0 }

        let sortedSamples = samples.sorted { $0.timestamp < $1.timestamp }
        var totalInterval: TimeInterval = 0

        for i in 1..<sortedSamples.count {
            totalInterval += sortedSamples[i].timestamp.timeIntervalSince(sortedSamples[i-1].timestamp)
        }

        let averageInterval = totalInterval / Double(samples.count - 1)
        return averageInterval / 60.0 // Convert to minutes
    }

    // MARK: - Data Quality Assessment

    /// Calculate data quality indicator for the day
    static func assessDataQuality(
        heartRateSamples: [HeartRateSample],
        hrvSamples: [HRVSample],
        sleepSummary: DailySleepSummary?,
        activitySummary: DailyActivitySummary?
    ) -> DataQualityIndicator {
        // Heart rate: expect at least 100 samples per day for good coverage
        let hrCompleteness = min(Double(heartRateSamples.count) / Double(Constants.DataQuality.minHeartRateSamplesPerDay), 1.0)

        // HRV: expect at least 3 samples for high confidence
        let hrvCompleteness = min(Double(hrvSamples.count) / Double(Constants.DataQuality.minHRVSamplesForHighConfidence), 1.0)

        // Sleep: based on whether we have sleep data and duration
        let sleepCompleteness: Double = {
            guard let sleep = sleepSummary, sleep.totalSleepHours >= Constants.DataQuality.minSleepHoursForHighConfidence else {
                return sleepSummary != nil ? 0.5 : 0.0
            }
            return 1.0
        }()

        // Activity: based on whether we have any activity data
        let activityCompleteness: Double = activitySummary != nil ? 1.0 : 0.0

        return DataQualityIndicator(
            heartRateCompleteness: hrCompleteness,
            hrvCompleteness: hrvCompleteness,
            sleepCompleteness: sleepCompleteness,
            activityCompleteness: activityCompleteness
        )
    }
}

// MARK: - Date Extension for Minutes

private extension Date {
    func adding(minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self)!
    }
}
