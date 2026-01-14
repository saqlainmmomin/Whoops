import Foundation

/// Recovery Score Engine: Inferred Metric with Full Transparency
/// Calculates a 0-100 recovery score based on physiological inputs.
struct RecoveryScoreEngine {

    // MARK: - Main Calculation

    /// Calculate recovery score with full component breakdown
    static func calculateRecoveryScore(
        hrvDeviation: Double?,      // z-score from baseline
        rhrDeviation: Double?,      // bpm delta from baseline
        sleepDurationRatio: Double?, // actual/baseline ratio
        sleepInterruptions: Int?,   // count of wake periods during sleep
        dataQuality: DataQualityIndicator
    ) -> RecoveryScore? {
        // Need at least some data to calculate
        guard hrvDeviation != nil || rhrDeviation != nil || sleepDurationRatio != nil else {
            return nil
        }

        // Calculate each component
        let hrvComponent = calculateHRVComponent(deviation: hrvDeviation)
        let rhrComponent = calculateRHRComponent(deviation: rhrDeviation)
        let sleepDurationComponent = calculateSleepDurationComponent(ratio: sleepDurationRatio)
        let interruptionComponent = calculateInterruptionComponent(count: sleepInterruptions)

        // Sum weighted contributions
        let totalScore = hrvComponent.contribution +
                        rhrComponent.contribution +
                        sleepDurationComponent.contribution +
                        interruptionComponent.contribution

        // Clamp to valid range
        let finalScore = StatisticalHelpers.clamp(Int(totalScore.rounded()), to: 0...100)

        // Calculate confidence based on data availability
        let confidence = calculateConfidence(
            hrvAvailable: hrvDeviation != nil,
            rhrAvailable: rhrDeviation != nil,
            sleepAvailable: sleepDurationRatio != nil,
            dataQuality: dataQuality
        )

        return RecoveryScore(
            score: finalScore,
            confidence: confidence,
            hrvComponent: hrvComponent,
            rhrComponent: rhrComponent,
            sleepDurationComponent: sleepDurationComponent,
            sleepInterruptionComponent: interruptionComponent
        )
    }

    // MARK: - Component Calculations

    /// HRV Component (40% weight)
    /// Higher HRV relative to baseline = better recovery
    private static func calculateHRVComponent(deviation: Double?) -> ScoreComponent {
        let weight = Constants.RecoveryWeights.hrv
        let name = "HRV Deviation"

        guard let zScore = deviation else {
            return ScoreComponent(
                name: name,
                rawValue: 0,
                normalizedValue: 50, // Neutral when missing
                weight: weight,
                contribution: 50 * weight
            )
        }

        // Normalize z-score (-2 to +2) to 0-100 scale
        // +2 z-score = 100 (excellent), -2 z-score = 0 (poor)
        let range = Constants.RecoveryWeights.hrvZScoreRange
        let normalized = StatisticalHelpers.normalizeToScale(
            value: zScore,
            fromRange: range,
            toRange: 0...100
        )

        return ScoreComponent(
            name: name,
            rawValue: zScore,
            normalizedValue: normalized,
            weight: weight,
            contribution: normalized * weight
        )
    }

    /// RHR Component (20% weight)
    /// Lower RHR relative to baseline = better recovery (inverted)
    private static func calculateRHRComponent(deviation: Double?) -> ScoreComponent {
        let weight = Constants.RecoveryWeights.restingHR
        let name = "Resting HR Deviation"

        guard let delta = deviation else {
            return ScoreComponent(
                name: name,
                rawValue: 0,
                normalizedValue: 50,
                weight: weight,
                contribution: 50 * weight
            )
        }

        // Invert: -10 bpm deviation = 100 (good), +10 bpm = 0 (bad)
        let range = Constants.RecoveryWeights.rhrDeviationRange
        let normalized = StatisticalHelpers.normalizeToScale(
            value: -delta, // Inverted
            fromRange: range,
            toRange: 0...100
        )

        return ScoreComponent(
            name: name,
            rawValue: delta,
            normalizedValue: normalized,
            weight: weight,
            contribution: normalized * weight
        )
    }

    /// Sleep Duration Component (25% weight)
    /// Sleep ratio close to or above 1.0 = better recovery
    private static func calculateSleepDurationComponent(ratio: Double?) -> ScoreComponent {
        let weight = Constants.RecoveryWeights.sleepDuration
        let name = "Sleep Duration"

        guard let sleepRatio = ratio else {
            return ScoreComponent(
                name: name,
                rawValue: 0,
                normalizedValue: 50,
                weight: weight,
                contribution: 50 * weight
            )
        }

        // 0.5 ratio = 0, 1.0 ratio = 75, 1.5+ ratio = 100
        let range = Constants.RecoveryWeights.sleepRatioRange
        let normalized = StatisticalHelpers.normalizeToScale(
            value: sleepRatio,
            fromRange: range,
            toRange: 0...100
        )

        return ScoreComponent(
            name: name,
            rawValue: sleepRatio * 100, // Show as percentage
            normalizedValue: normalized,
            weight: weight,
            contribution: normalized * weight
        )
    }

    /// Sleep Interruption Component (15% weight)
    /// Fewer interruptions = better recovery
    private static func calculateInterruptionComponent(count: Int?) -> ScoreComponent {
        let weight = Constants.RecoveryWeights.sleepInterruptions
        let name = "Sleep Interruptions"

        guard let interruptions = count else {
            return ScoreComponent(
                name: name,
                rawValue: 0,
                normalizedValue: 75, // Assume good if no data
                weight: weight,
                contribution: 75 * weight
            )
        }

        // 0 interruptions = 100, 5+ interruptions = 0
        let range = Constants.RecoveryWeights.interruptionRange
        let inverted = Double(range.upperBound - StatisticalHelpers.clamp(interruptions, to: range))
        let normalized = (inverted / Double(range.upperBound)) * 100

        return ScoreComponent(
            name: name,
            rawValue: Double(interruptions),
            normalizedValue: normalized,
            weight: weight,
            contribution: normalized * weight
        )
    }

    // MARK: - Confidence Calculation

    private static func calculateConfidence(
        hrvAvailable: Bool,
        rhrAvailable: Bool,
        sleepAvailable: Bool,
        dataQuality: DataQualityIndicator
    ) -> Confidence {
        var score = 0

        // Core data availability
        if hrvAvailable { score += 3 }
        if rhrAvailable { score += 2 }
        if sleepAvailable { score += 2 }

        // Data quality factors
        if dataQuality.hrvCompleteness > 0.5 { score += 1 }
        if dataQuality.sleepCompleteness > 0.5 { score += 1 }

        switch score {
        case 0...3: return .low
        case 4...6: return .medium
        default: return .high
        }
    }

    // MARK: - Decomposition for Transparency

    /// Generate full decomposition for UI display
    static func generateDecomposition(
        score: RecoveryScore,
        baseline: Baseline?
    ) -> RecoveryDecomposition {
        RecoveryDecomposition(recoveryScore: score, baseline: baseline)
    }

    // MARK: - Recovery Recommendations

    /// Generate recommendations based on recovery score
    static func generateRecommendations(score: RecoveryScore) -> [RecoveryRecommendation] {
        var recommendations: [RecoveryRecommendation] = []

        // Based on overall score
        switch score.category {
        case .low:
            recommendations.append(RecoveryRecommendation(
                type: .rest,
                title: "Prioritize Rest",
                description: "Your body shows signs of incomplete recovery. Consider light activity only."
            ))
        case .moderate:
            recommendations.append(RecoveryRecommendation(
                type: .moderate,
                title: "Moderate Activity OK",
                description: "You're partially recovered. Moderate intensity training is appropriate."
            ))
        case .high:
            recommendations.append(RecoveryRecommendation(
                type: .train,
                title: "Ready for Training",
                description: "Good recovery indicators. Your body can handle high intensity."
            ))
        }

        // Based on components
        if score.hrvComponent.normalizedValue < 40 {
            recommendations.append(RecoveryRecommendation(
                type: .hrv,
                title: "HRV Below Baseline",
                description: "Consider stress reduction techniques and ensure adequate sleep."
            ))
        }

        if score.rhrComponent.normalizedValue < 40 {
            recommendations.append(RecoveryRecommendation(
                type: .rhr,
                title: "Elevated Resting HR",
                description: "Your resting heart rate is elevated. Monitor for signs of overtraining."
            ))
        }

        if score.sleepDurationComponent.normalizedValue < 50 {
            recommendations.append(RecoveryRecommendation(
                type: .sleep,
                title: "Sleep Deficit",
                description: "You're not meeting your sleep baseline. Prioritize more sleep tonight."
            ))
        }

        return recommendations
    }
}

// MARK: - Recommendation Types

struct RecoveryRecommendation: Identifiable {
    var id: String { type.rawValue }

    let type: RecommendationType
    let title: String
    let description: String
}

enum RecommendationType: String {
    case rest = "rest"
    case moderate = "moderate"
    case train = "train"
    case hrv = "hrv"
    case rhr = "rhr"
    case sleep = "sleep"

    var icon: String {
        switch self {
        case .rest: return "bed.double.fill"
        case .moderate: return "figure.walk"
        case .train: return "figure.run"
        case .hrv: return "waveform.path.ecg"
        case .rhr: return "heart.fill"
        case .sleep: return "moon.fill"
        }
    }
}
