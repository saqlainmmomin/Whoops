import Foundation

// MARK: - Health Metric Protocol

protocol HealthMetric {
    var date: Date { get }
    var metricType: MetricType { get }
    var confidence: Confidence { get }
    var hasData: Bool { get }
}

// MARK: - Metric Value Protocol

protocol MetricValue {
    associatedtype Value
    var value: Value { get }
    var formattedValue: String { get }
    var unit: String { get }
}

// MARK: - Metric Decomposition (for transparency)

protocol MetricDecomposition {
    var inputValues: [MetricInput] { get }
    var formula: String { get }
    var timeWindow: String { get }
    var confidence: Confidence { get }
}

struct MetricInput: Identifiable {
    var id: String { name }

    let name: String
    let value: Double
    let formattedValue: String
    let unit: String
    let source: String  // "Heart Rate", "Sleep", etc.
    let timestamp: Date?

    init(name: String, value: Double, unit: String, source: String, timestamp: Date? = nil) {
        self.name = name
        self.value = value
        self.formattedValue = Self.format(value: value, unit: unit)
        self.unit = unit
        self.source = source
        self.timestamp = timestamp
    }

    private static func format(value: Double, unit: String) -> String {
        switch unit {
        case "bpm", "ms", "min", "kcal", "steps":
            return String(format: "%.0f %@", value, unit)
        case "hours", "km":
            return String(format: "%.1f %@", value, unit)
        case "%":
            return String(format: "%.0f%%", value)
        case "z-score":
            return String(format: "%+.2f", value)
        default:
            return String(format: "%.2f %@", value, unit)
        }
    }
}

// MARK: - Recovery Score Decomposition

struct RecoveryDecomposition: MetricDecomposition {
    let recoveryScore: RecoveryScore
    let baseline: Baseline?

    var inputValues: [MetricInput] {
        var inputs: [MetricInput] = []

        let hrvComp = recoveryScore.hrvComponent
        inputs.append(MetricInput(
            name: "HRV Deviation",
            value: hrvComp.rawValue,
            unit: "z-score",
            source: "Heart Rate Variability"
        ))

        let rhrComp = recoveryScore.rhrComponent
        inputs.append(MetricInput(
            name: "RHR Deviation",
            value: rhrComp.rawValue,
            unit: "bpm",
            source: "Resting Heart Rate"
        ))

        let sleepComp = recoveryScore.sleepDurationComponent
        inputs.append(MetricInput(
            name: "Sleep Ratio",
            value: sleepComp.rawValue,
            unit: "%",
            source: "Sleep"
        ))

        let interruptComp = recoveryScore.sleepInterruptionComponent
        inputs.append(MetricInput(
            name: "Sleep Interruptions",
            value: interruptComp.rawValue,
            unit: "count",
            source: "Sleep"
        ))

        return inputs
    }

    var formula: String {
        """
        Recovery = (HRV × 40%) + (RHR × 20%) + (Sleep Duration × 25%) + (Interruptions × 15%)

        Each component normalized to 0-100 scale based on:
        - HRV: z-score from 7-day baseline (range: -2 to +2)
        - RHR: deviation from baseline (range: -10 to +10 bpm)
        - Sleep: ratio vs baseline (range: 0.5 to 1.5)
        - Interruptions: count inverted (range: 0 to 5)
        """
    }

    var timeWindow: String {
        "Last night's sleep + this morning's HRV/RHR vs 7-day baseline"
    }

    var confidence: Confidence {
        recoveryScore.confidence
    }
}

// MARK: - Strain Score Decomposition

struct StrainDecomposition: MetricDecomposition {
    let strainScore: StrainScore
    let baseline: Baseline?

    var inputValues: [MetricInput] {
        var inputs: [MetricInput] = []

        let zoneComp = strainScore.zoneComponent
        inputs.append(MetricInput(
            name: "Weighted Zone Minutes",
            value: zoneComp.rawValue,
            unit: "min",
            source: "Heart Rate Zones"
        ))

        let durationComp = strainScore.durationComponent
        inputs.append(MetricInput(
            name: "Workout Duration",
            value: durationComp.rawValue,
            unit: "min",
            source: "Workouts"
        ))

        let energyComp = strainScore.energyComponent
        inputs.append(MetricInput(
            name: "Active Energy Ratio",
            value: energyComp.rawValue,
            unit: "%",
            source: "Activity"
        ))

        return inputs
    }

    var formula: String {
        """
        Strain = log(1 + weighted_zone_minutes) × energy_factor × 10

        Zone weights:
        - Zone 1 (Recovery): 0.1×
        - Zone 2 (Fat Burn): 0.3×
        - Zone 3 (Aerobic): 0.6×
        - Zone 4 (Anaerobic): 1.0×
        - Zone 5 (Max): 1.5×

        Energy factor = today's active energy / 7-day average
        """
    }

    var timeWindow: String {
        "Today's activity vs 7-day baseline"
    }

    var confidence: Confidence {
        strainScore.confidence
    }
}

// MARK: - Trend Direction

enum TrendDirection: String, Codable {
    case improving = "Improving"
    case stable = "Stable"
    case declining = "Declining"

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }
}
