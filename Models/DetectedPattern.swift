import Foundation
import SwiftData

// MARK: - Detected Pattern Model

@Model
final class DetectedPattern {
    var id: UUID
    var patternType: String        // "sleep_timing", "rest_day", "workout_recovery", "consistency"
    var inputMetric: String        // "bedtime", "workout", "hrv", etc.
    var outputMetric: String       // "recovery", "hrv", "strain", etc.
    var correlation: Double        // -1 to 1 (Pearson correlation)
    var confidence: String         // "low", "medium", "high"
    var sampleSize: Int            // Number of observations
    var descriptionText: String    // Human-readable description
    var recommendation: String     // Actionable advice
    var detectedDate: Date
    var isActive: Bool             // User can dismiss patterns
    var impactScore: Double        // Magnitude of effect (e.g., +15% recovery)

    init(
        patternType: String,
        inputMetric: String,
        outputMetric: String,
        correlation: Double,
        sampleSize: Int,
        descriptionText: String,
        recommendation: String,
        impactScore: Double
    ) {
        self.id = UUID()
        self.patternType = patternType
        self.inputMetric = inputMetric
        self.outputMetric = outputMetric
        self.correlation = correlation
        self.sampleSize = sampleSize
        self.descriptionText = descriptionText
        self.recommendation = recommendation
        self.detectedDate = Date()
        self.isActive = true
        self.impactScore = impactScore

        // Determine confidence based on correlation strength and sample size
        if sampleSize >= 14 && abs(correlation) >= 0.5 {
            self.confidence = "high"
        } else if sampleSize >= 7 && abs(correlation) >= 0.3 {
            self.confidence = "medium"
        } else {
            self.confidence = "low"
        }
    }

    // Display helpers
    var isPositive: Bool {
        correlation > 0
    }

    var correlationStrength: String {
        let absCorr = abs(correlation)
        switch absCorr {
        case 0.7...: return "Strong"
        case 0.4..<0.7: return "Moderate"
        case 0.2..<0.4: return "Weak"
        default: return "Very weak"
        }
    }

    var impactDescription: String {
        let sign = impactScore >= 0 ? "+" : ""
        if outputMetric == "recovery" || outputMetric == "hrv" {
            return "\(sign)\(Int(impactScore))% \(outputMetric)"
        } else {
            return "\(sign)\(Int(impactScore)) \(outputMetric)"
        }
    }

    var iconName: String {
        switch patternType {
        case "sleep_timing":
            return "moon.stars"
        case "rest_day":
            return "figure.mind.and.body"
        case "workout_recovery":
            return "figure.run"
        case "consistency":
            return "calendar"
        case "hrv_correlation":
            return "waveform.path.ecg"
        default:
            return "chart.line.uptrend.xyaxis"
        }
    }

    var categoryColor: String {
        switch patternType {
        case "sleep_timing":
            return "neonGreen"
        case "rest_day":
            return "neonTeal"
        case "workout_recovery":
            return "neonRed"
        case "consistency":
            return "neonGold"
        default:
            return "textGray"
        }
    }
}

// MARK: - Pattern Type Descriptions

enum PatternType: String, CaseIterable {
    case sleepTiming = "sleep_timing"
    case restDay = "rest_day"
    case workoutRecovery = "workout_recovery"
    case consistency = "consistency"
    case hrvCorrelation = "hrv_correlation"

    var displayName: String {
        switch self {
        case .sleepTiming: return "Sleep Timing"
        case .restDay: return "Rest Days"
        case .workoutRecovery: return "Workout Recovery"
        case .consistency: return "Consistency"
        case .hrvCorrelation: return "HRV Patterns"
        }
    }

    var description: String {
        switch self {
        case .sleepTiming:
            return "How your bedtime affects next-day recovery"
        case .restDay:
            return "Impact of rest days on your metrics"
        case .workoutRecovery:
            return "How workouts affect your recovery"
        case .consistency:
            return "Benefits of maintaining consistent habits"
        case .hrvCorrelation:
            return "Factors that influence your HRV"
        }
    }
}
