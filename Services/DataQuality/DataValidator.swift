import Foundation

/// Data validation for physiological metrics
/// Detects sensor anomalies and out-of-range values
struct DataValidator {

    // MARK: - Validation Result

    struct ValidationResult {
        let isValid: Bool
        let anomalyType: AnomalyType?
        let message: String?

        static let valid = ValidationResult(isValid: true, anomalyType: nil, message: nil)
    }

    // MARK: - Anomaly Types

    enum AnomalyType: String, CaseIterable {
        case rhrOutOfRange = "rhr_out_of_range"
        case hrvOutOfRange = "hrv_out_of_range"
        case sensorAnomaly = "sensor_anomaly"
        case sleepDurationAnomaly = "sleep_duration_anomaly"
        case heartRateSpike = "heart_rate_spike"
        case dataGap = "data_gap"

        var userMessage: String {
            switch self {
            case .rhrOutOfRange:
                return "Resting heart rate reading appears unusual. Check Apple Watch fit."
            case .hrvOutOfRange:
                return "HRV reading appears unusual. Ensure watch is snug during sleep."
            case .sensorAnomaly:
                return "Sensor data anomaly detected. Check Apple Watch fit."
            case .sleepDurationAnomaly:
                return "Sleep data may be incomplete. Ensure watch is worn to bed."
            case .heartRateSpike:
                return "Unusual heart rate pattern detected."
            case .dataGap:
                return "Data gap detected. Some metrics may be incomplete."
            }
        }
    }

    // MARK: - RHR Validation

    /// Validate RHR (physiologically possible: 30-120 bpm)
    static func validateRHR(_ rhr: Double) -> ValidationResult {
        // Physiologically impossible values
        guard rhr >= 25 && rhr <= 150 else {
            return ValidationResult(
                isValid: false,
                anomalyType: .rhrOutOfRange,
                message: "Sensor data anomaly detected. Check Apple Watch fit."
            )
        }

        // Unusual but possible - flag for review
        if rhr < 30 || rhr > 120 {
            return ValidationResult(
                isValid: true,
                anomalyType: .rhrOutOfRange,
                message: "Resting heart rate (\(Int(rhr)) bpm) is outside typical range."
            )
        }

        return .valid
    }

    // MARK: - HRV Validation

    /// Validate HRV (physiologically possible: 10-200 ms)
    static func validateHRV(_ hrv: Double) -> ValidationResult {
        // Physiologically impossible values
        guard hrv >= 5 && hrv <= 300 else {
            return ValidationResult(
                isValid: false,
                anomalyType: .hrvOutOfRange,
                message: "Sensor data anomaly detected. Check Apple Watch fit."
            )
        }

        // Unusual but possible
        if hrv < 10 || hrv > 200 {
            return ValidationResult(
                isValid: true,
                anomalyType: .hrvOutOfRange,
                message: "HRV (\(Int(hrv)) ms) is outside typical range."
            )
        }

        return .valid
    }

    // MARK: - Sleep Validation

    /// Validate sleep duration (0-16 hours considered valid)
    static func validateSleepDuration(_ hours: Double) -> ValidationResult {
        guard hours >= 0 && hours <= 24 else {
            return ValidationResult(
                isValid: false,
                anomalyType: .sleepDurationAnomaly,
                message: "Invalid sleep duration recorded."
            )
        }

        if hours > 14 {
            return ValidationResult(
                isValid: true,
                anomalyType: .sleepDurationAnomaly,
                message: "Unusually long sleep duration (\(String(format: "%.1f", hours)) hours)."
            )
        }

        return .valid
    }

    // MARK: - Heart Rate Spike Detection

    /// Check for sudden HR changes that may indicate sensor issues
    static func detectHeartRateSpike(
        previous: Double,
        current: Double,
        thresholdPercent: Double = 50
    ) -> ValidationResult {
        guard previous > 0 else { return .valid }

        let changePercent = abs(current - previous) / previous * 100

        if changePercent > thresholdPercent {
            return ValidationResult(
                isValid: true,
                anomalyType: .heartRateSpike,
                message: "Significant heart rate change detected (\(Int(changePercent))%)."
            )
        }

        return .valid
    }

    // MARK: - Outlier Filtering

    /// Exclude outliers from averages using IQR method
    static func filterOutliers<T: BinaryFloatingPoint>(
        _ values: [T],
        range: ClosedRange<T>
    ) -> [T] {
        values.filter { range.contains($0) }
    }

    /// Filter outliers using IQR method
    static func filterOutliersIQR(_ values: [Double], multiplier: Double = 1.5) -> [Double] {
        guard values.count >= 4 else { return values }

        let sorted = values.sorted()
        let q1Index = sorted.count / 4
        let q3Index = (sorted.count * 3) / 4

        let q1 = sorted[q1Index]
        let q3 = sorted[q3Index]
        let iqr = q3 - q1

        let lowerBound = q1 - (multiplier * iqr)
        let upperBound = q3 + (multiplier * iqr)

        return values.filter { $0 >= lowerBound && $0 <= upperBound }
    }

    /// Calculate median with outlier removal
    static func robustMedian(_ values: [Double]) -> Double {
        let filtered = filterOutliersIQR(values)
        guard !filtered.isEmpty else { return values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count) }

        let sorted = filtered.sorted()
        let count = sorted.count

        if count % 2 == 0 {
            return (sorted[count / 2 - 1] + sorted[count / 2]) / 2
        } else {
            return sorted[count / 2]
        }
    }

    // MARK: - Data Completeness

    /// Check data completeness for a metric
    static func checkDataCompleteness(
        samplesCount: Int,
        expectedMinimum: Int,
        metricName: String
    ) -> ValidationResult {
        if samplesCount < expectedMinimum {
            return ValidationResult(
                isValid: true,
                anomalyType: .dataGap,
                message: "\(metricName) data may be incomplete (\(samplesCount)/\(expectedMinimum) samples)."
            )
        }
        return .valid
    }

    // MARK: - Batch Validation

    /// Validate all metrics for a day
    static func validateDailyMetrics(_ metrics: DailyMetrics) -> [ValidationResult] {
        var results: [ValidationResult] = []

        // Validate RHR
        if let rhr = metrics.heartRate?.restingBPM {
            let result = validateRHR(rhr)
            if !result.isValid || result.anomalyType != nil {
                results.append(result)
            }
        }

        // Validate HRV
        if let hrv = metrics.hrv?.averageSDNN {
            let result = validateHRV(hrv)
            if !result.isValid || result.anomalyType != nil {
                results.append(result)
            }
        }

        // Validate sleep
        if let sleep = metrics.sleep {
            let result = validateSleepDuration(sleep.totalSleepHours)
            if !result.isValid || result.anomalyType != nil {
                results.append(result)
            }
        }

        return results
    }
}

// MARK: - Data Quality Summary

struct DataQualitySummary {
    let overallQuality: DataQuality
    let issues: [DataValidator.ValidationResult]
    let recommendations: [String]

    enum DataQuality: String {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"

        var color: String {
            switch self {
            case .excellent: return "optimal"
            case .good: return "neutral"
            case .fair: return "caution"
            case .poor: return "critical"
            }
        }
    }

    static func assess(validationResults: [DataValidator.ValidationResult]) -> DataQualitySummary {
        let invalidCount = validationResults.filter { !$0.isValid }.count
        let anomalyCount = validationResults.filter { $0.anomalyType != nil }.count

        let quality: DataQuality
        if invalidCount > 0 {
            quality = .poor
        } else if anomalyCount > 2 {
            quality = .fair
        } else if anomalyCount > 0 {
            quality = .good
        } else {
            quality = .excellent
        }

        let recommendations = validationResults
            .compactMap { $0.anomalyType?.userMessage }
            .removingDuplicates()

        return DataQualitySummary(
            overallQuality: quality,
            issues: validationResults.filter { $0.anomalyType != nil },
            recommendations: recommendations
        )
    }
}

// MARK: - Array Extension

private extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
