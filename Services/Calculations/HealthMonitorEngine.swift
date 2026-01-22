import Foundation

struct HealthMonitorResult {
    let metricsInRange: Int
    let totalMetrics: Int
    let flaggedMetrics: [String]

    var allMetricsGood: Bool {
        metricsInRange == totalMetrics
    }
}

@MainActor
class HealthMonitorEngine {

    static let shared = HealthMonitorEngine()

    private init() {}

    func evaluate(metrics: DailyMetrics, baseline: Baseline) -> HealthMonitorResult {
        var inRange = 0
        var flagged: [String] = []
        var totalChecked = 0

        // HRV check (within 1.5 std dev of baseline)
        if let hrv = metrics.hrv, let avgHRV = baseline.averageHRV, let stdDev = baseline.hrvStdDev {
            totalChecked += 1
            let hrvValue = hrv.nightlySDNN ?? hrv.averageSDNN
            let lowerBound = avgHRV - 1.5 * stdDev
            let upperBound = avgHRV + 1.5 * stdDev

            if hrvValue >= lowerBound && hrvValue <= upperBound {
                inRange += 1
            } else {
                flagged.append("HRV")
            }
        }

        // RHR check (within 1.5 std dev of baseline)
        if let heartRate = metrics.heartRate, let rhr = heartRate.restingBPM,
           let avgRHR = baseline.averageRestingHR, let stdDev = baseline.restingHRStdDev {
            totalChecked += 1
            let lowerBound = avgRHR - 1.5 * stdDev
            let upperBound = avgRHR + 1.5 * stdDev

            if rhr >= lowerBound && rhr <= upperBound {
                inRange += 1
            } else {
                flagged.append("RHR")
            }
        }

        // Recovery check (above 33)
        if let recovery = metrics.recoveryScore {
            totalChecked += 1
            if recovery.score > 33 {
                inRange += 1
            } else {
                flagged.append("Recovery")
            }
        }

        // Strain check (not overreaching, below 18 on 0-21 scale)
        if let strain = metrics.strainScore {
            totalChecked += 1
            // Convert 0-100 score to 0-21 scale
            let strainOn21Scale = Double(strain.score) / 100.0 * 21.0
            if strainOn21Scale <= 18 {
                inRange += 1
            } else {
                flagged.append("Strain")
            }
        }

        // Sleep check (at least 6 hours)
        if let sleep = metrics.sleep {
            totalChecked += 1
            if sleep.totalSleepHours >= 6 {
                inRange += 1
            } else {
                flagged.append("Sleep")
            }
        }

        return HealthMonitorResult(
            metricsInRange: inRange,
            totalMetrics: max(totalChecked, 5), // Ensure we show out of 5 even if data missing
            flaggedMetrics: flagged
        )
    }

    /// Evaluate with a default baseline when no baseline is available
    func evaluateWithDefaults(metrics: DailyMetrics) -> HealthMonitorResult {
        var inRange = 0
        var flagged: [String] = []
        var totalChecked = 0

        // HRV check (healthy range: 20-100ms)
        if let hrv = metrics.hrv {
            totalChecked += 1
            let hrvValue = hrv.nightlySDNN ?? hrv.averageSDNN
            if hrvValue >= 20 && hrvValue <= 100 {
                inRange += 1
            } else {
                flagged.append("HRV")
            }
        }

        // RHR check (healthy range: 40-80 bpm)
        if let heartRate = metrics.heartRate, let rhr = heartRate.restingBPM {
            totalChecked += 1
            if rhr >= 40 && rhr <= 80 {
                inRange += 1
            } else {
                flagged.append("RHR")
            }
        }

        // Recovery check
        if let recovery = metrics.recoveryScore {
            totalChecked += 1
            if recovery.score > 33 {
                inRange += 1
            } else {
                flagged.append("Recovery")
            }
        }

        // Strain check
        if let strain = metrics.strainScore {
            totalChecked += 1
            let strainOn21Scale = Double(strain.score) / 100.0 * 21.0
            if strainOn21Scale <= 18 {
                inRange += 1
            } else {
                flagged.append("Strain")
            }
        }

        // Sleep check
        if let sleep = metrics.sleep {
            totalChecked += 1
            if sleep.totalSleepHours >= 6 {
                inRange += 1
            } else {
                flagged.append("Sleep")
            }
        }

        return HealthMonitorResult(
            metricsInRange: inRange,
            totalMetrics: max(totalChecked, 5),
            flaggedMetrics: flagged
        )
    }
}
