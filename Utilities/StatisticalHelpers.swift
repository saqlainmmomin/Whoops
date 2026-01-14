import Foundation

struct StatisticalHelpers {

    // MARK: - Basic Statistics

    static func mean(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let count = sorted.count
        if count % 2 == 0 {
            return (sorted[count / 2 - 1] + sorted[count / 2]) / 2
        } else {
            return sorted[count / 2]
        }
    }

    static func standardDeviation(_ values: [Double]) -> Double? {
        guard values.count > 1, let avg = mean(values) else { return nil }
        let variance = values.reduce(0) { $0 + pow($1 - avg, 2) } / Double(values.count - 1)
        return sqrt(variance)
    }

    static func variance(_ values: [Double]) -> Double? {
        guard values.count > 1, let avg = mean(values) else { return nil }
        return values.reduce(0) { $0 + pow($1 - avg, 2) } / Double(values.count - 1)
    }

    static func min(_ values: [Double]) -> Double? {
        values.min()
    }

    static func max(_ values: [Double]) -> Double? {
        values.max()
    }

    static func range(_ values: [Double]) -> Double? {
        guard let minVal = values.min(), let maxVal = values.max() else { return nil }
        return maxVal - minVal
    }

    // MARK: - Z-Score

    static func zScore(value: Double, mean: Double, stdDev: Double) -> Double {
        guard stdDev > 0 else { return 0 }
        return (value - mean) / stdDev
    }

    static func zScore(value: Double, values: [Double]) -> Double? {
        guard let avg = mean(values), let std = standardDeviation(values), std > 0 else { return nil }
        return (value - avg) / std
    }

    // MARK: - Percentile

    static func percentile(_ values: [Double], percentile: Double) -> Double? {
        guard !values.isEmpty, percentile >= 0, percentile <= 100 else { return nil }
        let sorted = values.sorted()
        let index = (percentile / 100) * Double(sorted.count - 1)
        let lower = Int(floor(index))
        let upper = Int(ceil(index))

        if lower == upper {
            return sorted[lower]
        }

        let weight = index - Double(lower)
        return sorted[lower] * (1 - weight) + sorted[upper] * weight
    }

    // MARK: - Normalization

    static func normalize(value: Double, min: Double, max: Double) -> Double {
        guard max > min else { return 0.5 }
        return (value - min) / (max - min)
    }

    static func normalize(value: Double, range: ClosedRange<Double>) -> Double {
        normalize(value: value, min: range.lowerBound, max: range.upperBound)
    }

    static func normalizeToScale(value: Double, fromRange: ClosedRange<Double>, toRange: ClosedRange<Double>) -> Double {
        let normalized = normalize(value: value, range: fromRange)
        let clamped = Swift.min(Swift.max(normalized, 0), 1)
        return toRange.lowerBound + clamped * (toRange.upperBound - toRange.lowerBound)
    }

    // MARK: - Clamping

    static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(value, range.lowerBound), range.upperBound)
    }

    static func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(value, range.lowerBound), range.upperBound)
    }

    // MARK: - Rolling Calculations

    static func rollingMean(_ values: [Double], windowSize: Int) -> [Double] {
        guard windowSize > 0, values.count >= windowSize else { return [] }

        var result: [Double] = []
        for i in (windowSize - 1)..<values.count {
            let window = Array(values[(i - windowSize + 1)...i])
            if let avg = mean(window) {
                result.append(avg)
            }
        }
        return result
    }

    static func exponentialMovingAverage(_ values: [Double], alpha: Double) -> [Double] {
        guard !values.isEmpty, alpha > 0, alpha <= 1 else { return [] }

        var ema: [Double] = [values[0]]
        for i in 1..<values.count {
            let newValue = alpha * values[i] + (1 - alpha) * ema[i - 1]
            ema.append(newValue)
        }
        return ema
    }

    // MARK: - Trend Analysis

    static func linearRegression(_ values: [Double]) -> (slope: Double, intercept: Double)? {
        guard values.count >= 2 else { return nil }

        let n = Double(values.count)
        let xValues = (0..<values.count).map { Double($0) }

        let sumX = xValues.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(xValues, values).reduce(0) { $0 + $1.0 * $1.1 }
        let sumXX = xValues.reduce(0) { $0 + $1 * $1 }

        let denominator = n * sumXX - sumX * sumX
        guard denominator != 0 else { return nil }

        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n

        return (slope, intercept)
    }

    static func trendDirection(slope: Double, threshold: Double = 0.1) -> TrendDirection {
        if slope > threshold {
            return .improving
        } else if slope < -threshold {
            return .declining
        } else {
            return .stable
        }
    }

    // MARK: - Correlation

    static func pearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double? {
        guard x.count == y.count, x.count >= 2 else { return nil }

        guard let meanX = mean(x), let meanY = mean(y),
              let stdX = standardDeviation(x), let stdY = standardDeviation(y),
              stdX > 0, stdY > 0 else { return nil }

        let covariance = zip(x, y).reduce(0) { $0 + ($1.0 - meanX) * ($1.1 - meanY) } / Double(x.count - 1)
        return covariance / (stdX * stdY)
    }
}

// MARK: - Array Extensions

extension Array where Element == Double {
    var mean: Double? { StatisticalHelpers.mean(self) }
    var median: Double? { StatisticalHelpers.median(self) }
    var standardDeviation: Double? { StatisticalHelpers.standardDeviation(self) }
    var variance: Double? { StatisticalHelpers.variance(self) }

    func zScore(for value: Double) -> Double? {
        StatisticalHelpers.zScore(value: value, values: self)
    }

    func percentile(_ p: Double) -> Double? {
        StatisticalHelpers.percentile(self, percentile: p)
    }

    func rollingMean(windowSize: Int) -> [Double] {
        StatisticalHelpers.rollingMean(self, windowSize: windowSize)
    }

    func ema(alpha: Double) -> [Double] {
        StatisticalHelpers.exponentialMovingAverage(self, alpha: alpha)
    }
}
