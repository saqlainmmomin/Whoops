import Foundation

/// Strain Score Engine: Inferred Metric with Full Transparency
/// Calculates a 0-100 strain score based on cardiovascular load.
struct StrainScoreEngine {

    // MARK: - Main Calculation

    /// Calculate strain score with full component breakdown
    static func calculateStrainScore(
        zoneDistribution: ZoneTimeDistribution?,
        workoutDurationMinutes: Int,
        activeEnergy: Double,
        baselineActiveEnergy: Double?,
        dataQuality: DataQualityIndicator
    ) -> StrainScore {
        // Calculate each component
        let zoneComponent = calculateZoneComponent(distribution: zoneDistribution)
        let durationComponent = calculateDurationComponent(minutes: workoutDurationMinutes)
        let energyComponent = calculateEnergyComponent(
            energy: activeEnergy,
            baseline: baselineActiveEnergy
        )

        // Apply log-scaled formula
        let rawStrain = calculateRawStrain(
            weightedZoneMinutes: zoneComponent.rawValue,
            energyFactor: energyComponent.rawValue / 100.0
        )

        // Scale to 0-100
        let scaledScore = scaleStrainScore(rawStrain)
        let finalScore = StatisticalHelpers.clamp(scaledScore, to: 0...100)

        // Calculate confidence
        let confidence = calculateConfidence(
            hasZoneData: zoneDistribution != nil,
            hasWorkoutData: workoutDurationMinutes > 0,
            dataQuality: dataQuality
        )

        return StrainScore(
            score: finalScore,
            confidence: confidence,
            zoneComponent: zoneComponent,
            durationComponent: durationComponent,
            energyComponent: energyComponent
        )
    }

    // MARK: - Component Calculations

    /// Zone Time Component (50% weight)
    /// Weighted minutes in elevated HR zones
    private static func calculateZoneComponent(distribution: ZoneTimeDistribution?) -> ScoreComponent {
        let weight = Constants.StrainWeights.zoneContribution
        let name = "HR Zone Time"

        guard let zones = distribution else {
            return ScoreComponent(
                name: name,
                rawValue: 0,
                normalizedValue: 0,
                weight: weight,
                contribution: 0
            )
        }

        let weightedMinutes = zones.weightedStrainMinutes

        // Normalize: 0 minutes = 0, 100+ weighted minutes = 100
        let normalized = min(weightedMinutes, 100)

        return ScoreComponent(
            name: name,
            rawValue: weightedMinutes,
            normalizedValue: normalized,
            weight: weight,
            contribution: normalized * weight
        )
    }

    /// Workout Duration Component (30% weight)
    private static func calculateDurationComponent(minutes: Int) -> ScoreComponent {
        let weight = Constants.StrainWeights.durationContribution
        let name = "Workout Duration"

        // Normalize: 0 min = 0, 60+ min = 100
        let normalized = min(Double(minutes) / 60.0 * 100, 100)

        return ScoreComponent(
            name: name,
            rawValue: Double(minutes),
            normalizedValue: normalized,
            weight: weight,
            contribution: normalized * weight
        )
    }

    /// Energy Component (20% weight)
    /// Active energy relative to baseline
    private static func calculateEnergyComponent(
        energy: Double,
        baseline: Double?
    ) -> ScoreComponent {
        let weight = Constants.StrainWeights.energyContribution
        let name = "Active Energy"

        let baselineEnergy = baseline ?? 500 // Default baseline if none available
        let ratio = energy / max(baselineEnergy, 1) * 100

        // Normalize: 50% = 0, 100% = 50, 200%+ = 100
        let normalized = StatisticalHelpers.normalizeToScale(
            value: ratio,
            fromRange: 50...200,
            toRange: 0...100
        )

        return ScoreComponent(
            name: name,
            rawValue: ratio,
            normalizedValue: normalized,
            weight: weight,
            contribution: normalized * weight
        )
    }

    // MARK: - Strain Formula

    /// Calculate raw strain using log-scaled formula
    private static func calculateRawStrain(
        weightedZoneMinutes: Double,
        energyFactor: Double
    ) -> Double {
        // strain = log(1 + weighted_zone_minutes) * energy_factor * scale_factor
        let logComponent = log(1 + weightedZoneMinutes)
        let adjustedEnergyFactor = max(energyFactor, 0.5) // Minimum 0.5x
        return logComponent * adjustedEnergyFactor * Constants.StrainWeights.logScaleFactor
    }

    /// Scale raw strain to 0-100 range
    private static func scaleStrainScore(_ rawStrain: Double) -> Int {
        // Typical range: 0-50 for raw strain
        // Scale so that:
        // - 0 raw = 0 score
        // - 20 raw = ~50 score (moderate day)
        // - 40+ raw = 100 score (very high strain day)
        let scaled = (rawStrain / 40.0) * 100
        return Int(min(scaled, 100).rounded())
    }

    // MARK: - Confidence Calculation

    private static func calculateConfidence(
        hasZoneData: Bool,
        hasWorkoutData: Bool,
        dataQuality: DataQualityIndicator
    ) -> Confidence {
        var score = 0

        if hasZoneData { score += 3 }
        if hasWorkoutData { score += 2 }
        if dataQuality.heartRateCompleteness > 0.5 { score += 2 }
        if dataQuality.activityCompleteness > 0.5 { score += 1 }

        switch score {
        case 0...2: return .low
        case 3...5: return .medium
        default: return .high
        }
    }

    // MARK: - Weekly Strain Accumulation

    /// Calculate 7-day cumulative strain
    static func calculateWeeklyStrain(dailyStrainScores: [Int]) -> Int {
        let sum = dailyStrainScores.suffix(7).reduce(0, +)
        // Weekly strain: sum of daily strains, max 700 (but typically much lower)
        return min(sum, 700)
    }

    /// Calculate strain trend
    static func calculateStrainTrend(
        dailyStrainScores: [Int],
        windowDays: Int = 7
    ) -> TrendDirection? {
        let values = dailyStrainScores.suffix(windowDays).map { Double($0) }
        guard values.count >= 3 else { return nil }

        guard let trend = BaselineEngine.detectTrend(values: values, windowDays: windowDays) else {
            return nil
        }

        return trend.direction
    }

    // MARK: - Decomposition for Transparency

    /// Generate full decomposition for UI display
    static func generateDecomposition(
        score: StrainScore,
        baseline: Baseline?
    ) -> StrainDecomposition {
        StrainDecomposition(strainScore: score, baseline: baseline)
    }

    // MARK: - Strain-Recovery Balance

    /// Analyze strain relative to recovery
    static func analyzeStrainRecoveryBalance(
        strainScore: Int,
        recoveryScore: Int
    ) -> StrainRecoveryBalance {
        let ratio = Double(strainScore) / max(Double(recoveryScore), 1)

        switch ratio {
        case ..<0.5:
            return StrainRecoveryBalance(
                status: .underLoaded,
                description: "Low strain relative to recovery. Room for more intensity."
            )
        case 0.5..<0.8:
            return StrainRecoveryBalance(
                status: .balanced,
                description: "Good balance between strain and recovery."
            )
        case 0.8..<1.2:
            return StrainRecoveryBalance(
                status: .optimal,
                description: "Optimal training load matching your recovery capacity."
            )
        case 1.2..<1.5:
            return StrainRecoveryBalance(
                status: .pushing,
                description: "Pushing beyond recovery. Monitor for fatigue."
            )
        default:
            return StrainRecoveryBalance(
                status: .overreaching,
                description: "Strain significantly exceeds recovery. Rest recommended."
            )
        }
    }
}

// MARK: - Supporting Types

struct StrainRecoveryBalance {
    let status: BalanceStatus
    let description: String
}

enum BalanceStatus: String {
    case underLoaded = "Under Loaded"
    case balanced = "Balanced"
    case optimal = "Optimal"
    case pushing = "Pushing"
    case overreaching = "Overreaching"

    var icon: String {
        switch self {
        case .underLoaded: return "arrow.down.circle"
        case .balanced: return "equal.circle"
        case .optimal: return "checkmark.circle"
        case .pushing: return "exclamationmark.circle"
        case .overreaching: return "xmark.circle"
        }
    }
}

// MARK: - Zone Analysis

extension StrainScoreEngine {

    /// Analyze HR zone distribution
    static func analyzeZoneDistribution(_ distribution: ZoneTimeDistribution) -> ZoneAnalysis {
        let total = distribution.totalMinutes
        guard total > 0 else {
            return ZoneAnalysis(
                dominantZone: nil,
                intensityLevel: .none,
                description: "No HR zone data recorded"
            )
        }

        // Find dominant zone
        let zones: [(HRZone, Int)] = [
            (.zone1, distribution.zone1Minutes),
            (.zone2, distribution.zone2Minutes),
            (.zone3, distribution.zone3Minutes),
            (.zone4, distribution.zone4Minutes),
            (.zone5, distribution.zone5Minutes)
        ]

        let dominant = zones.max { $0.1 < $1.1 }

        // Calculate intensity level
        let highIntensityMinutes = distribution.zone4Minutes + distribution.zone5Minutes
        let highIntensityRatio = Double(highIntensityMinutes) / Double(total)

        let intensityLevel: IntensityLevel
        if highIntensityRatio > 0.3 {
            intensityLevel = .high
        } else if highIntensityRatio > 0.1 {
            intensityLevel = .moderate
        } else if total > 30 {
            intensityLevel = .low
        } else {
            intensityLevel = .minimal
        }

        let description = generateZoneDescription(
            dominant: dominant?.0,
            intensityLevel: intensityLevel,
            totalMinutes: total
        )

        return ZoneAnalysis(
            dominantZone: dominant?.0,
            intensityLevel: intensityLevel,
            description: description
        )
    }

    private static func generateZoneDescription(
        dominant: HRZone?,
        intensityLevel: IntensityLevel,
        totalMinutes: Int
    ) -> String {
        guard let zone = dominant else {
            return "No significant HR zone activity"
        }

        switch intensityLevel {
        case .high:
            return "High intensity session with \(totalMinutes) min total, primarily in \(zone.name)"
        case .moderate:
            return "Moderate intensity with \(totalMinutes) min, mostly \(zone.name)"
        case .low:
            return "Low intensity activity: \(totalMinutes) min in \(zone.name)"
        case .minimal:
            return "Minimal cardio load: \(totalMinutes) min recorded"
        case .none:
            return "No HR zone data"
        }
    }
}

struct ZoneAnalysis {
    let dominantZone: HRZone?
    let intensityLevel: IntensityLevel
    let description: String
}

enum IntensityLevel: String {
    case none = "None"
    case minimal = "Minimal"
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
}
