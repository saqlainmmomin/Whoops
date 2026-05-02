# Whoops Data Pipeline Contract — spec.md

**Version:** 1.0
**Branch:** `data/healthkit-pipeline`
**Hardware Target:** Apple Watch Series 5
**Last Updated:** 2026-02-27
**Status:** ACTIVE — Antigravity frontend agent may proceed with data-shape-dependent rendering.

---

## Signal: Antigravity Unblock

> **DATA CONTRACT EMITTED.** The Antigravity frontend agent is unblocked for all data-shape-dependent component rendering. All property names, types, units, and nil behaviors below are canonical. Bind directly to `HealthDataViewModel` published properties.

---

## ViewModel: `HealthDataViewModel`

**File:** `ViewModels/HealthDataViewModel.swift`
**Actor:** `@MainActor`
**Observation:** `ObservableObject` with `@Published` properties
**Import:** `import Combine`

---

## Data Contract — All Published Properties

### Recovery Score Proxy (Tier 3 — Inferred)

| Property | Swift Type | HK Identifier | Unit | Update Frequency | Nil Behavior | Series 5 Available |
|----------|-----------|---------------|------|-------------------|-------------|---------------------|
| `recoveryScore` | `Int?` | Composite (HRV + RHR + Sleep) | score 0-100 | daily | `nil` — display "--" | Yes (derived) |
| `recoveryCategory` | `String?` | Composite | "Low" / "Moderate" / "High" | daily | `nil` — display "Unknown" | Yes (derived) |
| `recoveryConfidence` | `Confidence?` | Composite | .low / .medium / .high | daily | `nil` — hide confidence indicator | Yes (derived) |

### Strain Score Proxy (Tier 3 — Inferred)

| Property | Swift Type | HK Identifier | Unit | Update Frequency | Nil Behavior | Series 5 Available |
|----------|-----------|---------------|------|-------------------|-------------|---------------------|
| `strainScore` | `Double?` | Composite (HR zones + Energy) | score 0-21 (Whoop scale) | daily | `nil` — display "0.0" | Yes (derived) |
| `strainCategory` | `String?` | Composite | "Light" / "Moderate" / "High" | daily | `nil` — display "Light" | Yes (derived) |
| `strainConfidence` | `Confidence?` | Composite | .low / .medium / .high | daily | `nil` — hide confidence indicator | Yes (derived) |

### Resting Heart Rate (Tier 1 — Factual)

| Property | Swift Type | HK Identifier | Unit | Update Frequency | Nil Behavior | Series 5 Available |
|----------|-----------|---------------|------|-------------------|-------------|---------------------|
| `restingHeartRate` | `Double?` | `HKQuantityTypeIdentifierRestingHeartRate` | bpm | daily | `nil` — display "--" | Yes |
| `restingHeartRateTrend` | `TrendDirection?` | Derived | .improving / .stable / .declining | daily | `nil` — hide trend arrow | Yes (derived) |
| `restingHeartRateBaseline` | `Double?` | Derived (28-day avg) | bpm | daily | `nil` — display "Calculating..." | Yes (derived) |

### Heart Rate Variability — SDNN (Tier 1 — Factual)

| Property | Swift Type | HK Identifier | Unit | Update Frequency | Nil Behavior | Series 5 Available |
|----------|-----------|---------------|------|-------------------|-------------|---------------------|
| `hrvSDNN` | `Double?` | `HKQuantityTypeIdentifierHeartRateVariabilitySDNN` | ms | daily (nightly preferred) | `nil` — display "--" | Yes (SDNN only) |
| `hrvTrend` | `TrendDirection?` | Derived | .improving / .stable / .declining | daily | `nil` — hide trend arrow | Yes (derived) |
| `hrvBaseline` | `Double?` | Derived (28-day avg) | ms | daily | `nil` — display "Calculating..." | Yes (derived) |

### Blood Oxygen — SpO2 (Tier 1 — Factual, Foreground Only)

| Property | Swift Type | HK Identifier | Unit | Update Frequency | Nil Behavior | Series 5 Available |
|----------|-----------|---------------|------|-------------------|-------------|---------------------|
| `spo2Percentage` | `Double?` | `HKQuantityTypeIdentifierOxygenSaturation` | % (0-100) | on-demand (foreground spot-check) | `nil` — display "--" | Yes (foreground only) |
| `spo2Timestamp` | `Date?` | Derived | ISO 8601 | on-demand | `nil` — hide timestamp | Yes |
| `spo2Available` | `Bool` | Derived | true / false | on-change | `false` — show "No readings" | Yes |

> **Series 5 Constraint:** SpO2 does NOT support background delivery. The value is only updated when the user manually takes a reading with the Watch face up. No continuous monitoring.

### Sleep Duration (Tier 1 — Factual)

| Property | Swift Type | HK Identifier | Unit | Update Frequency | Nil Behavior | Series 5 Available |
|----------|-----------|---------------|------|-------------------|-------------|---------------------|
| `sleepDurationHours` | `Double?` | `HKCategoryTypeIdentifierSleepAnalysis` | hours | daily | `nil` — display "--" | Yes |
| `sleepNeededHours` | `Double?` | Derived (28-day avg) | hours | daily | `nil` — display "7:30" (default) | Yes (derived) |
| `sleepPerformanceScore` | `Int?` | Derived (duration / needed) | score 0-100 | daily | `nil` — display "0%" | Yes (derived) |

### Sleep Stages (Tier 1 — Factual)

| Property | Swift Type | HK Identifier | Unit | Update Frequency | Nil Behavior | Series 5 Available |
|----------|-----------|---------------|------|-------------------|-------------|---------------------|
| `sleepStageDeep` | `Int?` | `HKCategoryValueSleepAnalysis.asleepDeep` | minutes | daily | `nil` — display "--" | Yes (iOS 16+) |
| `sleepStageREM` | `Int?` | `HKCategoryValueSleepAnalysis.asleepREM` | minutes | daily | `nil` — display "--" | Yes (iOS 16+) |
| `sleepStageCore` | `Int?` | `HKCategoryValueSleepAnalysis.asleepCore` | minutes | daily | `nil` — display "--" | Yes (iOS 16+) |
| `sleepStageAwake` | `Int?` | `HKCategoryValueSleepAnalysis.awake` | minutes | daily | `nil` — display "--" | Yes |
| `sleepBedtime` | `Date?` | Derived from sleep session | ISO 8601 | daily | `nil` — display "--:--" | Yes |
| `sleepWakeTime` | `Date?` | Derived from sleep session | ISO 8601 | daily | `nil` — display "--:--" | Yes |

> **Note:** Sleep stage classification (Deep/REM/Core) requires iOS 16+ and watchOS 9+. On older OS versions, all sleep is reported as `.asleepUnspecified`. The pipeline handles this gracefully.

### Active Energy (Tier 1 — Factual)

| Property | Swift Type | HK Identifier | Unit | Update Frequency | Nil Behavior | Series 5 Available |
|----------|-----------|---------------|------|-------------------|-------------|---------------------|
| `activeEnergyKcal` | `Double?` | `HKQuantityTypeIdentifierActiveEnergyBurned` | kcal | hourly | `nil` — display "0" | Yes |
| `basalEnergyKcal` | `Double?` | `HKQuantityTypeIdentifierBasalEnergyBurned` | kcal | hourly | `nil` — display "0" | Yes |
| `totalEnergyKcal` | `Double?` | Derived (active + basal) | kcal | hourly | `nil` — display "0" | Yes (derived) |

### Respiratory Rate (Tier 1 — Factual)

| Property | Swift Type | HK Identifier | Unit | Update Frequency | Nil Behavior | Series 5 Available |
|----------|-----------|---------------|------|-------------------|-------------|---------------------|
| `respiratoryRate` | `Double?` | `HKQuantityTypeIdentifierRespiratoryRate` | breaths/min | daily | `nil` — display "N/A" | Yes |
| `respiratoryRateBaseline` | `Double?` | Derived (28-day avg) | breaths/min | daily | `nil` — hide baseline | Yes (derived) |

### Pipeline Metadata

| Property | Swift Type | HK Identifier | Unit | Update Frequency | Nil Behavior | Series 5 Available |
|----------|-----------|---------------|------|-------------------|-------------|---------------------|
| `pipelineState` | `PipelineState` | N/A | enum | on-change | `.idle` | N/A |
| `authorizationState` | `HealthKitAuthorizationStatus` | N/A | enum | on-change | `.notDetermined` | N/A |
| `lastRefreshDate` | `Date?` | N/A | ISO 8601 | on-refresh | `nil` — display "Never" | N/A |
| `errors` | `[PipelineError]` | N/A | array | on-change | `[]` — no errors | N/A |
| `baselineDaysCollected` | `Int` | N/A | count (0-28) | daily | `0` | N/A |
| `dataQuality` | `DataQualityIndicator?` | N/A | struct | daily | `nil` — assume poor quality | N/A |

### Weekly Trend Data (Chart Binding)

| Property | Swift Type | HK Identifier | Unit | Update Frequency | Nil Behavior | Series 5 Available |
|----------|-----------|---------------|------|-------------------|-------------|---------------------|
| `weeklyRecoveryScores` | `[Int]` | Composite | score 0-100 | daily | `[]` — empty chart | Yes (derived) |
| `weeklyStrainScores` | `[Double]` | Composite | score 0-21 | daily | `[]` — empty chart | Yes (derived) |
| `weeklyHRV` | `[Double]` | HRV SDNN | ms | daily | `[]` — empty chart | Yes |
| `weeklyRHR` | `[Double]` | Resting HR | bpm | daily | `[]` — empty chart | Yes |
| `weeklySleepHours` | `[Double]` | Sleep Analysis | hours | daily | `[]` — empty chart | Yes |
| `weeklyActiveEnergy` | `[Double]` | Active Energy | kcal | daily | `[]` — empty chart | Yes |

---

## Supporting Types

### `PipelineState` (enum)
```
idle | authorizing | authorizationDenied | loading | ready | error
```

### `PipelineError` (enum, Identifiable)
```
authorizationRequired | authorizationFailed(String) | queryFailed(String, String) | noData(String)
```

### `TrendDirection` (enum)
```
improving | stable | declining
```

### `Confidence` (enum)
```
low | medium | high
```

### `DataQualityIndicator` (struct)
```swift
heartRateCompleteness: Double   // 0-1
hrvCompleteness: Double         // 0-1
sleepCompleteness: Double       // 0-1
activityCompleteness: Double    // 0-1
```

---

## ViewModel API Surface

### Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `requestAuthorization()` | `async` | Request HealthKit read permissions (Series 5 scoped) |
| `refreshAllData()` | `async` | Full pipeline refresh — fetches today + 28-day history |
| `fetchIncrementalUpdates()` | `async` | Anchored object query for new samples since last fetch |

---

## Series 5 Hardware Constraints Summary

| Capability | Available | Notes |
|------------|-----------|-------|
| Heart Rate (continuous) | Yes | Optical sensor, background delivery eligible |
| Resting Heart Rate | Yes | Daily aggregate |
| HRV (SDNN) | Yes | SDNN method only, no time-domain analysis |
| SpO2 | Yes (foreground only) | No background delivery, requires user-initiated reading |
| ECG | Yes (AFib only) | AFib classification, no raw waveform export |
| Sleep Analysis | Yes | Stage classification requires iOS 16+ / watchOS 9+ |
| Active Energy | Yes | Background delivery eligible |
| Respiratory Rate | Yes | Nightly estimation |
| Blood Glucose | **No** | Requires external CGM hardware |
| Skin Temperature | **No** | Series 8+ only |
| Crash Detection | **No** | Series 8+ / SE 2nd gen+ only |
| Cycling Cadence | **No** | Series 8+ only |
| Water Temperature | **No** | Ultra only |
| Running Biomechanics | **No** | Series 6+ only |

---

## File Manifest

| File | Purpose |
|------|---------|
| `Services/HealthKit/HealthKitPermissions.swift` | Series 5 permission manifest and type filters |
| `Services/HealthKit/HealthKitPipeline.swift` | SpO2 queries, anchored queries, statistics collection, background delivery |
| `Services/HealthKit/HealthKitManager.swift` | Core HealthKit query implementations (existing) |
| `Services/HealthKit/HKQueryBuilders.swift` | Predicate and sort descriptor builders (existing) |
| `Services/HealthKit/HKDataMappers.swift` | HK sample to domain model mappers (existing) |
| `Services/HealthKit/HealthKitCache.swift` | NSCache wrapper for query results (existing) |
| `ViewModels/HealthDataViewModel.swift` | Published state objects — **bind frontend here** |
| `Models/DailyMetrics.swift` | Core data model (existing) |
| `Models/HeartRateData.swift` | HR/HRV/Zone types (existing) |
| `Models/SleepData.swift` | Sleep stage/session types (existing) |
| `spec.md` | This file — canonical data contract |

---

## Binding Example (for Antigravity agent)

```swift
// In any SwiftUI view:
@EnvironmentObject var healthData: HealthDataViewModel

// Recovery gauge
Text("\(healthData.recoveryScore ?? 0)%")

// Strain value
Text(String(format: "%.1f", healthData.strainScore ?? 0.0))

// HRV with nil handling
Text(healthData.hrvSDNN.map { "\(Int($0))ms" } ?? "--")

// SpO2 with availability check
if healthData.spo2Available {
    Text("\(healthData.spo2Percentage.map { "\(Int($0))%" } ?? "--")")
}

// Sleep stages
if let deep = healthData.sleepStageDeep {
    Text("\(deep) min deep")
}

// Weekly chart data
SparklineChart(data: healthData.weeklyRecoveryScores.map { Double($0) })
```
