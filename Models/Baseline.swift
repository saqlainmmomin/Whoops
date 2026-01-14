import Foundation
import SwiftData

// MARK: - Baseline Model

struct Baseline: Sendable {
    let calculatedDate: Date
    let windowDays: Int  // 7 or 28

    // Heart Rate Baselines
    let averageRestingHR: Double?
    let restingHRStdDev: Double?

    // HRV Baselines
    let averageHRV: Double?
    let hrvStdDev: Double?

    // Sleep Baselines
    let averageSleepDuration: Double?  // hours
    let sleepDurationStdDev: Double?
    let averageBedtime: Int?  // minutes from midnight (can be negative)
    let bedtimeStdDev: Double?
    let averageWakeTime: Int?  // minutes from midnight
    let wakeTimeStdDev: Double?
    let averageSleepEfficiency: Double?

    // Activity Baselines
    let averageActiveEnergy: Double?
    let activeEnergyStdDev: Double?
    let averageSteps: Double?
    let stepsStdDev: Double?

    // Workout Baselines
    let averageWorkoutMinutes: Double?
    let workoutMinutesStdDev: Double?
    let averageWorkoutsPerWeek: Double?

    // Load Baselines
    let averageDailyLoad: Double?
    let loadStdDev: Double?

    // Sample sizes for confidence
    let heartRateSampleDays: Int
    let hrvSampleDays: Int
    let sleepSampleDays: Int
    let activitySampleDays: Int

    // Computed properties for deviation calculations

    func hrvZScore(for value: Double) -> Double? {
        guard let avg = averageHRV, let std = hrvStdDev, std > 0 else { return nil }
        return (value - avg) / std
    }

    func rhrDeviation(from value: Double) -> Double? {
        guard let avg = averageRestingHR else { return nil }
        return value - avg
    }

    func sleepDurationRatio(for hours: Double) -> Double? {
        guard let avg = averageSleepDuration, avg > 0 else { return nil }
        return hours / avg
    }

    func activeEnergyRatio(for energy: Double) -> Double? {
        guard let avg = averageActiveEnergy, avg > 0 else { return nil }
        return energy / avg
    }

    func bedtimeDeviation(from minutes: Int) -> Double? {
        guard let avg = averageBedtime else { return nil }
        return Double(minutes - avg)
    }

    func wakeTimeDeviation(from minutes: Int) -> Double? {
        guard let avg = averageWakeTime else { return nil }
        return Double(minutes - avg)
    }

    // Confidence based on sample size
    var confidence: Confidence {
        let totalSamples = heartRateSampleDays + hrvSampleDays + sleepSampleDays + activitySampleDays
        let maxPossible = windowDays * 4

        let ratio = Double(totalSamples) / Double(maxPossible)
        switch ratio {
        case ..<0.5: return .low
        case 0.5..<0.75: return .medium
        default: return .high
        }
    }
}

extension Baseline: Codable {}

// MARK: - Baseline Builder

struct BaselineBuilder {

    static func build7DayBaseline(from metrics: [DailyMetrics], asOf date: Date) -> Baseline {
        buildBaseline(from: metrics, windowDays: 7, asOf: date)
    }

    static func build28DayBaseline(from metrics: [DailyMetrics], asOf date: Date) -> Baseline {
        buildBaseline(from: metrics, windowDays: 28, asOf: date)
    }

    private static func buildBaseline(from metrics: [DailyMetrics], windowDays: Int, asOf date: Date) -> Baseline {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -windowDays, to: date)!

        let relevantMetrics = metrics.filter { metric in
            metric.date >= startDate && metric.date < date
        }

        // Extract values
        let restingHRValues = relevantMetrics.compactMap { $0.heartRate?.restingBPM }
        let hrvValues = relevantMetrics.compactMap { $0.hrv?.nightlySDNN ?? $0.hrv?.averageSDNN }
        let sleepDurations = relevantMetrics.compactMap { $0.sleep?.totalSleepHours }
        let activeEnergies = relevantMetrics.compactMap { $0.activity?.activeEnergy }
        let steps = relevantMetrics.compactMap { $0.activity?.steps }.map { Double($0) }
        let workoutMinutes = relevantMetrics.compactMap { $0.workouts?.totalDurationMinutes }.map { Double($0) }

        // Extract sleep timing
        let bedtimes = relevantMetrics.compactMap { metric -> Int? in
            guard let bedtime = metric.sleep?.bedtime else { return nil }
            return SleepTiming(bedtime: bedtime, wakeTime: bedtime).bedtimeMinutesSinceMidnight
        }
        let wakeTimes = relevantMetrics.compactMap { metric -> Int? in
            guard let wakeTime = metric.sleep?.wakeTime else { return nil }
            return SleepTiming(bedtime: wakeTime, wakeTime: wakeTime).wakeTimeMinutesSinceMidnight
        }
        let efficiencies = relevantMetrics.compactMap { $0.sleep?.averageEfficiency }

        return Baseline(
            calculatedDate: date,
            windowDays: windowDays,
            averageRestingHR: average(restingHRValues),
            restingHRStdDev: standardDeviation(restingHRValues),
            averageHRV: average(hrvValues),
            hrvStdDev: standardDeviation(hrvValues),
            averageSleepDuration: average(sleepDurations),
            sleepDurationStdDev: standardDeviation(sleepDurations),
            averageBedtime: bedtimes.isEmpty ? nil : Int(average(bedtimes.map { Double($0) }) ?? 0),
            bedtimeStdDev: standardDeviation(bedtimes.map { Double($0) }),
            averageWakeTime: wakeTimes.isEmpty ? nil : Int(average(wakeTimes.map { Double($0) }) ?? 0),
            wakeTimeStdDev: standardDeviation(wakeTimes.map { Double($0) }),
            averageSleepEfficiency: average(efficiencies),
            averageActiveEnergy: average(activeEnergies),
            activeEnergyStdDev: standardDeviation(activeEnergies),
            averageSteps: average(steps),
            stepsStdDev: standardDeviation(steps),
            averageWorkoutMinutes: average(workoutMinutes),
            workoutMinutesStdDev: standardDeviation(workoutMinutes),
            averageWorkoutsPerWeek: {
                let totalWorkouts = relevantMetrics.reduce(0) { $0 + ($1.workouts?.totalWorkouts ?? 0) }
                return Double(totalWorkouts) / Double(windowDays) * 7.0
            }(),
            averageDailyLoad: average(relevantMetrics.compactMap { $0.acuteLoad }),
            loadStdDev: standardDeviation(relevantMetrics.compactMap { $0.acuteLoad }),
            heartRateSampleDays: relevantMetrics.filter { $0.heartRate != nil }.count,
            hrvSampleDays: relevantMetrics.filter { $0.hrv != nil }.count,
            sleepSampleDays: relevantMetrics.filter { $0.sleep != nil }.count,
            activitySampleDays: relevantMetrics.filter { $0.activity != nil }.count
        )
    }

    // MARK: - Statistical Helpers

    private static func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func standardDeviation(_ values: [Double]) -> Double? {
        guard values.count > 1, let avg = average(values) else { return nil }
        let variance = values.reduce(0) { $0 + pow($1 - avg, 2) } / Double(values.count - 1)
        return sqrt(variance)
    }
}

// MARK: - SwiftData Persistent Model

@Model
final class BaselineRecord {
    @Attribute(.unique) var id: String  // "7day-YYYY-MM-DD" or "28day-YYYY-MM-DD"
    var baselineJSON: Data

    init(id: String, baselineJSON: Data) {
        self.id = id
        self.baselineJSON = baselineJSON
    }

    @MainActor
    convenience init(baseline: Baseline) throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: baseline.calculatedDate)
        let id = "\(baseline.windowDays)day-\(dateString)"
        let data = try JSONEncoder().encode(baseline)
        self.init(id: id, baselineJSON: data)
    }

    nonisolated func getBaseline() throws -> Baseline {
        try JSONDecoder().decode(Baseline.self, from: baselineJSON)
    }
}
