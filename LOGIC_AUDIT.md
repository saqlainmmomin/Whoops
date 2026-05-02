# Whoops Logic Audit

## Audit Scope
- `ViewModels/DashboardViewModel.swift`
- `ViewModels/TimelineViewModel.swift`
- `ViewModels/ExportViewModel.swift`
- `ViewModels/HealthDataViewModel.swift`
- `Services/Calculations/*`
- `Services/Persistence/LocalStore.swift`
- `Services/HealthKit/HealthKitManager.swift`
- `Models/DailyMetrics.swift`

## Current State
- The repo already contains the raw pieces for a coaching engine:
  - Tier 1 factual metrics
  - Tier 2 deterministic calculations
  - recovery and strain engines
  - baseline logic
  - local persistence
- The app does not yet have one canonical assessment pipeline.
- Domain logic is duplicated in view models and split across multiple parallel model families.

## Findings

### 1. Raw HealthKit -> `DailyMetrics` mapping is duplicated
- `DashboardViewModel.processRawData`
- `TimelineViewModel.processRawData`
- `ExportViewModel.processRawData`
- `HealthDataViewModel.buildDailyMetrics`
- Impact:
  - same Tier 1 assembly exists in four places
  - changes to Tier 1 logic can silently drift across screens
  - view models own domain assembly work they should not own

### 2. Recovery logic has two conflicting product definitions
- `RecoveryScoreEngine.calculateReadinessState` uses newer Whoop-aligned weights and `ReadinessState`
- `RecoveryScoreEngine.calculateRecoveryScore` uses legacy weighted components and `RecoveryScore`
- `DashboardViewModel`, `TimelineViewModel`, and `HealthDataViewModel` still rely on `calculateRecoveryScore`
- Impact:
  - the codebase has two different meanings for “recovery”
  - the product contract is unclear
  - downstream UI could diverge depending on which path gets used

### 3. Strain logic also has two conflicting product definitions
- `StrainScoreEngine.calculateWhoopStrain` produces `StrainScore21`
- `StrainScoreEngine.calculateStrainScore` produces legacy `StrainScore` on `0...100`
- `HealthDataViewModel` converts the legacy `0...100` score back into a `0...21` proxy
- Impact:
  - strain target and completed strain are not clearly separated
  - the app reports strain, but coaching requires target strain
  - conversion from one scale into another is a product smell, not a domain truth

### 4. Sleep coaching is not yet a first-class output
- `SleepPerformanceEngine` exists
- `AlarmManager` has bedtime utilities
- no shared daily assessment produces canonical sleep need, bedtime guidance, headline, blocker, and action together
- Impact:
  - sleep data is present
  - sleep coaching is not yet the product layer

### 5. View models still calculate domain logic directly
- `DashboardViewModel` calculates baselines, Tier 2 metrics, recovery, strain, and trends
- `TimelineViewModel` recalculates baselines and scores
- `HealthDataViewModel` calculates separate “proxy” scores
- Impact:
  - business logic is not isolated behind shared services
  - changes require touching multiple screens
  - confidence and recommendation behavior can diverge

### 6. Persistence access is duplicated despite `LocalStore`
- `LocalStore` already provides shared SwiftData helpers
- `DashboardViewModel`, `TimelineViewModel`, and `ExportViewModel` still implement their own fetch/cache methods
- Impact:
  - duplicated persistence code
  - inconsistent update behavior
  - repeated silent failure handling with `print`

### 7. Authorization state handling is too optimistic
- `HealthKitManager.checkAuthorizationStatus()` maps `.sharingDenied` to `.authorized`
- Impact:
  - violates the repo instruction to handle denied and unknown states explicitly
  - risks false-ready UI state

### 8. Trend and weekly context are partially ad hoc
- `DashboardViewModel` manually derives sleep and RHR trends
- `BaselineEngine` already contains some trend helpers
- Impact:
  - trend logic is not centralized
  - rationale for trend thresholds is inconsistent across metrics

## Canonical Formula Decisions For This Refactor

### Recovery
- Canonical product output remains `Recovery` on `0...100`
- Keep `RecoveryScore` as the current app-facing output for now because the dashboard already consumes it
- Treat `ReadinessState` as an intermediate/legacy parallel model until it is either merged or removed
- Near-term decision:
  - use one shared builder and one shared assessment engine
  - stop recalculating recovery inside multiple view models

### Strain
- Canonical coaching output should be `Strain Target` on `0...21`
- Completed strain can remain as supporting context
- For the first slice:
  - keep the existing `StrainScore` calculation as supporting load context
  - derive target strain deterministically from recovery and recent load
  - stop using ad hoc per-view-model scale conversion

### Sleep
- Canonical coaching output should be `Sleep Need` plus `Bedtime Recommendation`
- Use baseline sleep duration as the initial sleep-need anchor
- Adjust conservatively for sleep debt and suppressed recovery
- Explicitly mark bedtime precision as low-confidence when no strong wake-time anchor exists

## Deprecation Targets
- duplicated `processRawData` methods across view models
- view-model-owned recovery and strain calculation helpers
- view-model-owned cache wrappers where `LocalStore` should be used
- `HealthDataViewModel` proxy score path as a separate source of truth
- parallel “legacy” vs “Session 7” domain branches without one assessment entry point

## Exact First Implementation Slice For Phase 3
- Introduce `DailyAssessment` as the shared product-facing assessment model.
- Introduce `DailyMetricsBuilder` as the only place that converts raw HealthKit data into `DailyMetrics`.
- Introduce `DailyAssessmentPipeline` as the first shared orchestration service:
  - fetch today + recent history
  - reuse `LocalStore`
  - compute baselines
  - enrich metrics with Tier 2 calculations
  - compute recovery
  - compute completed strain context
  - compute target strain
  - compute sleep need and bedtime guidance
  - emit one headline, one blocker, one action, and warnings
- Refactor `DashboardViewModel` to consume that pipeline first.
- Refactor `TimelineViewModel` and `ExportViewModel` to use `DailyMetricsBuilder` immediately, even if they do not yet consume the full assessment model.

## Why This Slice First
- It removes real duplication without requiring a home-screen redesign yet.
- It creates the missing service boundary the repo instructions call for.
- It keeps UI churn low while making later recovery/strain/sleep redesign safer.
- It gives the app one place to express uncertainty and recommendation rules.

## Follow-On After This Slice
- Move timeline and export persistence fully to `LocalStore`
- Replace `HealthDataViewModel` proxy logic with `DailyAssessment`
- tighten HealthKit authorization handling
- make the home screen render assessment-first rather than metric-first
