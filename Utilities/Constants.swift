import Foundation

enum Constants {

    // MARK: - Recovery Score Weights

    enum RecoveryWeights {
        static let hrv: Double = 0.40          // 40% weight
        static let restingHR: Double = 0.20    // 20% weight
        static let sleepDuration: Double = 0.25 // 25% weight
        static let sleepInterruptions: Double = 0.15 // 15% weight

        // Normalization ranges
        static let hrvZScoreRange: ClosedRange<Double> = -2.0...2.0
        static let rhrDeviationRange: ClosedRange<Double> = -10.0...10.0
        static let sleepRatioRange: ClosedRange<Double> = 0.5...1.5
        static let interruptionRange: ClosedRange<Int> = 0...5
    }

    // MARK: - Strain Score Weights

    enum StrainWeights {
        static let zoneContribution: Double = 0.50  // 50% from HR zones
        static let durationContribution: Double = 0.30  // 30% from duration
        static let energyContribution: Double = 0.20  // 20% from energy

        // Zone strain multipliers
        static let zone1Multiplier: Double = 0.1
        static let zone2Multiplier: Double = 0.3
        static let zone3Multiplier: Double = 0.6
        static let zone4Multiplier: Double = 1.0
        static let zone5Multiplier: Double = 1.5

        // Scaling factor for log calculation
        static let logScaleFactor: Double = 10.0
    }

    // MARK: - Heart Rate Zones

    enum HeartRateZones {
        static let zone1Range: ClosedRange<Double> = 0.50...0.60  // % of max HR
        static let zone2Range: ClosedRange<Double> = 0.60...0.70
        static let zone3Range: ClosedRange<Double> = 0.70...0.80
        static let zone4Range: ClosedRange<Double> = 0.80...0.90
        static let zone5Range: ClosedRange<Double> = 0.90...1.00

        // Default max HR formula: 220 - age
        static func estimatedMaxHR(age: Int) -> Double {
            Double(220 - age)
        }

        // Conservative default for unknown age
        static let defaultMaxHR: Double = 185.0
    }

    // MARK: - Sleep Thresholds

    enum SleepThresholds {
        static let minimumSleepHours: Double = 4.0
        static let optimalSleepHoursMin: Double = 7.0
        static let optimalSleepHoursMax: Double = 9.0

        // Sleep stage ideal percentages
        static let deepSleepIdealMin: Double = 0.13
        static let deepSleepIdealMax: Double = 0.23
        static let remSleepIdealMin: Double = 0.20
        static let remSleepIdealMax: Double = 0.25
        static let coreSleepIdealMin: Double = 0.50
        static let coreSleepIdealMax: Double = 0.60

        // Sleep efficiency threshold
        static let goodEfficiencyThreshold: Double = 85.0
    }

    // MARK: - Activity Load

    enum ActivityLoad {
        // Acute/Chronic load ratio thresholds
        static let optimalLoadRatioMin: Double = 0.8
        static let optimalLoadRatioMax: Double = 1.3
        static let highRiskLoadRatio: Double = 1.5
        static let lowLoadRatio: Double = 0.8

        // Exponential decay factors for load calculations
        static let acuteDecayFactor: Double = 0.85   // 7-day window
        static let chronicDecayFactor: Double = 0.95  // 28-day window
    }

    // MARK: - HR Recovery

    enum HRRecovery {
        // 1-minute HR recovery thresholds
        static let excellentRecovery: Double = 30.0  // > 30 bpm drop
        static let goodRecovery: Double = 20.0       // > 20 bpm drop
        static let averageRecovery: Double = 12.0    // > 12 bpm drop
        // Below 12 bpm = below average
    }

    // MARK: - Data Quality

    enum DataQuality {
        // Minimum samples needed for confidence
        static let minHRVSamplesForHighConfidence: Int = 3
        static let minSleepHoursForHighConfidence: Double = 4.0
        static let minHeartRateSamplesPerDay: Int = 100

        // Baseline calculation requirements
        static let minDaysFor7DayBaseline: Int = 4
        static let minDaysFor28DayBaseline: Int = 14
    }

    // MARK: - Score Ranges

    enum ScoreRanges {
        static let fullRange: ClosedRange<Int> = 0...100

        // Recovery categories
        static let lowRecoveryRange: ClosedRange<Int> = 0...33
        static let moderateRecoveryRange: ClosedRange<Int> = 34...66
        static let highRecoveryRange: ClosedRange<Int> = 67...100

        // Strain categories
        static let lightStrainRange: ClosedRange<Int> = 0...33
        static let moderateStrainRange: ClosedRange<Int> = 34...66
        static let highStrainRange: ClosedRange<Int> = 67...100
    }

    // MARK: - Baseline Windows

    enum BaselineWindows {
        static let shortWindow: Int = 7   // 7 days
        static let longWindow: Int = 28   // 28 days
        static let trendWindow: Int = 30  // 30 days for trend analysis
        static let fitnessWindow: Int = 90 // 90 days for fitness trend
    }

    // MARK: - UI Constants

    enum UI {
        static let defaultAnimationDuration: Double = 0.3
        static let cardCornerRadius: Double = 16.0
        static let gaugeLineWidth: Double = 12.0

        // Colors for score ranges
        static func recoveryColor(for score: Int) -> String {
            switch score {
            case 0...33: return "red"
            case 34...66: return "yellow"
            default: return "green"
            }
        }

        static func strainColor(for score: Int) -> String {
            switch score {
            case 0...33: return "blue"
            case 34...66: return "orange"
            default: return "red"
            }
        }
    }

    // MARK: - Export

    enum Export {
        static let csvDelimiter: String = ","
        static let dateFormat: String = "yyyy-MM-dd"
        static let timestampFormat: String = "yyyy-MM-dd HH:mm:ss"
    }
}
