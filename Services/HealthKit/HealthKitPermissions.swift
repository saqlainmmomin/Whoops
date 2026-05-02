import Foundation
import HealthKit

// MARK: - Apple Watch Series 5 HealthKit Permission Manifest
// Hardware ceiling: Series 5 (2019)
// Excluded types: blood glucose, skin temperature, crash detection, cycling cadence,
//                 water temperature, underwater depth, cycling speed

/// Centralized permission manifest scoped to Apple Watch Series 5 capabilities.
/// All HKSampleType collections are hard-filtered against this manifest.
struct HealthKitPermissions {

    // MARK: - Series 5 Supported Read Types

    /// All HKObjectTypes this app requests read access for.
    /// Every type listed here is confirmed available on Apple Watch Series 5.
    static var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()

        for identifier in supportedQuantityTypes {
            if let type = HKQuantityType.quantityType(forIdentifier: identifier) {
                types.insert(type)
            }
        }

        for identifier in supportedCategoryTypes {
            if let type = HKCategoryType.categoryType(forIdentifier: identifier) {
                types.insert(type)
            }
        }

        types.insert(HKWorkoutType.workoutType())

        // ECG (Series 4+ — Series 5 supported, AFib classification only)
        if HKHealthStore.isHealthDataAvailable() {
            types.insert(HKObjectType.electrocardiogramType())
        }

        return types
    }

    // MARK: - Quantity Types (Series 5)

    static let supportedQuantityTypes: [HKQuantityTypeIdentifier] = [
        // Heart rate telemetry
        .heartRate,                         // Continuous — bpm
        .restingHeartRate,                  // Daily aggregate — bpm
        .heartRateVariabilitySDNN,          // SDNN method only — ms

        // Blood oxygen — foreground spot-check ONLY, no background delivery on S5
        .oxygenSaturation,

        // Activity
        .activeEnergyBurned,               // Cumulative — kcal
        .basalEnergyBurned,                // Cumulative — kcal
        .stepCount,                        // Cumulative — count
        .distanceWalkingRunning,           // Cumulative — km

        // Respiratory
        .respiratoryRate,                  // Discrete — breaths/min

        // Cardio fitness
        .vo2Max,                           // Discrete — mL/kg/min

        // Body measurements (from iPhone Health app, not Watch sensor)
        .height,
        .bodyMass,
        .bodyTemperature,                  // Manual/thermometer entry only
    ]

    // MARK: - Category Types (Series 5)

    static let supportedCategoryTypes: [HKCategoryTypeIdentifier] = [
        .sleepAnalysis,                    // Sleep stages (Core/Deep/REM on iOS 16+)
    ]

    // MARK: - Series 5 Exclusions (Hard Filters)

    /// Types NOT available on Apple Watch Series 5.
    /// Used as a deny-list to filter out any accidental queries.
    static let excludedQuantityTypes: [HKQuantityTypeIdentifier] = [
        .bloodGlucose,                     // Requires external CGM
        .appleSleepingWristTemperature,    // Series 8+ only
        .cyclingCadence,                   // Series 8+ only
        .cyclingSpeed,                     // Series 8+ only
        .underwaterDepth,                  // Ultra only
        .waterTemperature,                 // Ultra only
        .runningStrideLength,              // Series 6+ / SE 2nd gen+
        .runningVerticalOscillation,       // Series 6+
        .runningGroundContactTime,         // Series 6+
        .runningPower,                     // Series 6+
    ]

    // MARK: - Validation

    /// Returns true if the given identifier is supported on Series 5 hardware.
    static func isSeries5Supported(_ identifier: HKQuantityTypeIdentifier) -> Bool {
        supportedQuantityTypes.contains(identifier) && !excludedQuantityTypes.contains(identifier)
    }

    /// Filter a set of HKObjectTypes to only those supported on Series 5.
    static func filterToSeries5(_ types: Set<HKObjectType>) -> Set<HKObjectType> {
        let excludedSet = Set(excludedQuantityTypes.compactMap {
            HKQuantityType.quantityType(forIdentifier: $0)
        } as [HKObjectType])

        return types.subtracting(excludedSet)
    }

    // MARK: - SpO2 Constraints

    /// SpO2 on Series 5 is foreground-only spot-check.
    /// No background delivery is available.
    static let spo2BackgroundDeliveryAvailable = false

    /// SpO2 requires the user to hold still with the Watch face up.
    static let spo2RequiresForeground = true

    // MARK: - ECG Constraints

    /// ECG on Series 5 supports AFib classification only (no waveform voltage data export).
    static let ecgClassificationOnly = true

    // MARK: - Background Delivery Eligibility

    /// Types eligible for background delivery on Series 5.
    /// SpO2 is explicitly excluded (foreground-only on S5).
    static let backgroundDeliveryTypes: [HKQuantityTypeIdentifier] = [
        .heartRate,
        .restingHeartRate,
        .heartRateVariabilitySDNN,
        .activeEnergyBurned,
        .stepCount,
        .distanceWalkingRunning,
    ]

    /// Check if a type supports background delivery on Series 5.
    static func supportsBackgroundDelivery(_ identifier: HKQuantityTypeIdentifier) -> Bool {
        backgroundDeliveryTypes.contains(identifier)
    }
}
