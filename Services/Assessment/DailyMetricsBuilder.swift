import Foundation

struct DailyMetricsBuilder {
    func build(from raw: RawDailyHealthData) -> DailyMetrics {
        let date = raw.date
        let sleepWindow = DateHelpers.sleepWindow(for: date)

        let heartRateSummary = Tier1Calculator.calculateHeartRateSummary(
            heartRateSamples: raw.heartRateSamples,
            restingHRSamples: raw.restingHeartRateSamples,
            for: date
        )

        let hrvSummary = Tier1Calculator.calculateHRVSummary(
            hrvSamples: raw.hrvSamples,
            sleepWindow: sleepWindow,
            for: date
        )

        let sleepSummary = Tier1Calculator.calculateSleepSummary(
            sleepSamples: raw.sleepSamples,
            for: date
        )

        let workoutSummary = Tier1Calculator.calculateWorkoutSummary(
            workouts: raw.workouts,
            for: date
        )

        let activitySummary = Tier1Calculator.calculateActivitySummary(
            steps: raw.steps,
            distance: raw.distance,
            activeEnergy: raw.activeEnergy,
            basalEnergy: raw.basalEnergy,
            for: date
        )

        let zoneDistribution = Tier1Calculator.calculateZoneDistribution(
            heartRateSamples: raw.heartRateSamples,
            maxHeartRate: Constants.HeartRateZones.defaultMaxHR
        )

        var hrRecovery: HRRecoveryData?
        if let lastWorkout = raw.workouts.last {
            hrRecovery = Tier1Calculator.calculateHRRecovery(
                workout: lastWorkout,
                heartRateSamples: raw.heartRateSamples
            )
        }

        let dataQuality = Tier1Calculator.assessDataQuality(
            heartRateSamples: raw.heartRateSamples,
            hrvSamples: raw.hrvSamples,
            sleepSummary: sleepSummary,
            activitySummary: activitySummary
        )

        return DailyMetrics(
            date: date,
            heartRate: heartRateSummary,
            hrv: hrvSummary,
            sleep: sleepSummary,
            workouts: workoutSummary,
            activity: activitySummary,
            zoneDistribution: zoneDistribution,
            hrRecovery: hrRecovery,
            acuteLoad: nil,
            chronicLoad: nil,
            loadRatio: nil,
            sleepDebt: nil,
            hrvDeviation: nil,
            rhrDeviation: nil,
            sleepTimingConsistency: nil,
            recoveryScore: nil,
            strainScore: nil,
            dataQuality: dataQuality
        )
    }
}
