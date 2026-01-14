# Whoops Development Context

## Project Overview

**App Name:** Whoops
**Purpose:** Apple Health Physiology Analytics - Whoop-equivalent metrics using native HealthKit data
**Platform:** iOS 17.6+ (SwiftUI + SwiftData)
**Data Policy:** All data stays on-device, no cloud sync

---

## Development Timeline

### Session 1 (Jan 11, 2025) - Initial Build
- Created complete project structure with 38+ Swift files
- Implemented three-tier metric system:
  - **Tier 1 (Factual):** Raw health data from HealthKit
  - **Tier 2 (Deterministic):** Calculated metrics (load ratios, z-scores, sleep debt)
  - **Tier 3 (Inferred):** Recovery and Strain scores
- Set up SwiftData persistence with `DailyMetricsRecord` and `BaselineRecord`
- Configured HealthKit integration for HR, HRV, Sleep, Workouts, Activity

### Session 2 (Jan 12-13, 2025) - Bug Fixes & Recovery
**Issues Encountered:**
1. **Disk space crisis** - System disk at 98% full caused widespread file corruption
2. **Actor isolation errors** - Swift 6 strict concurrency with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
3. **Project configuration issues** - Xcode 16's `PBXFileSystemSynchronizedRootGroup` misconfiguration

**Fixes Applied:**

| Issue | Solution | Files Affected |
|-------|----------|----------------|
| Actor isolation for Codable | Changed to `extension Model: @preconcurrency Codable {}` | `Baseline.swift`, `DailyMetrics.swift` |
| Missing source folders in build | Added all folders to `fileSystemSynchronizedGroups` | `project.pbxproj` |
| Corrupted files from disk full | Restored from backup at `/Users/saqlainmomin/Whoops/Whoops/` | 30+ files |
| Info.plist duplicate output | Removed file, using auto-generation via build settings | `project.pbxproj` |
| SwiftData predicate errors | Captured variables before predicate, used in-memory filtering for `hasPrefix()` | `LocalStore.swift` |
| Missing Combine import | Added `import Combine` to files using `@Published` | ViewModels, Views |

### Session 3 (Jan 13, 2025) - Sovereign Dark UI Refactor
**Design Pivot:** Transitioned from "MVP functionality" to "High-Fidelity Quantified Self"
**Target Aesthetic:** Whoop-style premium data visualization

**Changes Implemented:**

| Category | Change | Files |
|----------|--------|-------|
| **Dark Mode** | Forced `.preferredColorScheme(.dark)` globally | `WhoopsApp.swift` |
| **Theme System** | Created `Theme.swift` with Sovereign palette (neonTeal, neonRed, sovereignBlack) | `Utilities/Theme.swift` [NEW] |
| **Circular Gauges** | Recovery/Strain visualization with neon glow effects | `Views/Components/SovereignGauge.swift` [NEW] |
| **Data Cards** | Dense metric display cards for HRV, RHR, Sleep, Calories | `Views/Components/DeepDataCard.swift` [NEW] |
| **Dashboard** | Replaced List with ZStack + ScrollView, hero gauges, LazyVGrid | `Views/Dashboard/DashboardView.swift` |
| **Profile Tensor** | New "Matrix" style profile page with biometric sliders | `Views/Profile/ProfileTensorView.swift` [NEW] |
| **Navigation** | Added TabView for Dashboard/Profile switching | `WhoopsApp.swift` |
| **Bug Fixes** | Fixed invalid Range `100...0` causing fatal crash | `Services/Calculations/Tier2Calculator.swift` |
| **Code Cleanup** | Removed unnecessary `@preconcurrency` annotations | `Baseline.swift`, `DailyMetrics.swift` |

**Design Tokens (Theme.swift):**
```swift
Theme.Colors.sovereignBlack   // #000000 - OLED black
Theme.Colors.neonTeal         // #00E5FF - Recovery accent
Theme.Colors.neonRed          // #FF003C - Strain accent
Theme.Colors.neonGreen        // #00FF94 - Sleep/positive
Theme.Colors.neonGold         // #FFD700 - Warning/calories
Theme.Colors.panelGray        // #1C1C1E - Card backgrounds
```

### Session 4 (Jan 14, 2025) - Interactive Features & Habit Building
**Major Upgrade:** Transformed from read-only dashboard to interactive habit-building app

**Features Implemented:**

| Feature | Description |
|---------|-------------|
| **Onboarding Flow** | Multi-step welcome with name input, HealthKit permission |
| **Expandable Metrics** | All dashboard cards/gauges tappable, push to detail views |
| **Sparkline Charts** | Mini 7-day trend graphs on each DeepDataCard |
| **Interactive Charts** | Full MetricLineChart with 7/28/90 day time range picker |
| **Habits Tab** | Pattern detection, goal tracking, weekly reports |
| **Timeline Comparison** | Side-by-side day comparison with "What Changed" analysis |
| **Smart Notifications** | Low recovery alerts, bedtime reminders, weekly digest |
| **Profile Polish** | Real user data from SwiftData, notification settings |

**New Files Created:**

| Category | Files |
|----------|-------|
| **Models** | `UserProfile.swift`, `Goal.swift`, `DetectedPattern.swift`, `WeeklyReport.swift` |
| **Views/Onboarding** | `OnboardingView.swift` |
| **Views/Habits** | `HabitsView.swift` (includes PatternCard, GoalCard, WeeklyReportCard, GoalCreationSheet) |
| **Views/Timeline** | `ComparisonView.swift` |
| **Views/Settings** | `NotificationSettingsView.swift` |
| **Views/Charts** | `SparklineChart.swift`, `MetricLineChart.swift` |
| **Services/Habits** | `PatternDetector.swift` |
| **Services/Notifications** | `NotificationManager.swift` |
| **ViewModels** | `HabitsViewModel.swift` |

**Files Modified:**

| File | Changes |
|------|---------|
| `WhoopsApp.swift` | Added UserProfile, Goal, DetectedPattern, WeeklyReport to schema; onboarding flow; Habits tab |
| `DashboardView.swift` | Wrapped in NavigationStack; tappable NavigationLinks; sparklines in cards |
| `DeepDataCard.swift` | Added trend indicator and sparkline content slot |
| `TimelineView.swift` | Added comparison mode with multi-selection UI |
| `ProfileTensorView.swift` | Connected to UserProfile via @Query; notification settings link |
| `HealthKitManager.swift` | Added `fetchUserCharacteristics()` for age/sex/height/weight |
| `DailyMetrics.swift` | Added `placeholder(for:)` static method for previews |

**Bug Fixes:**
- Added `import Combine` to `NotificationManager.swift` and `HabitsViewModel.swift` (ObservableObject conformance)

**Technical Patterns Introduced:**
- NavigationStack with `navigationDestination(for: MetricType.self)` router
- Comparison mode with multi-selection state (`compareFirstDay`, `compareSecondDay`)
- Pattern detection using Pearson correlation
- NotificationManager singleton with `@AppStorage` preferences
- Swift Charts framework for SparklineChart and MetricLineChart

---

## Current Project Structure

```
Whoops/
├── App/
│   ├── WhoopsApp.swift          # @main entry, SwiftData container, TabView, onboarding
│   └── AppState.swift           # Global app state, MetricType enum
│
├── Models/
│   ├── HealthMetric.swift       # Base metric protocol
│   ├── HeartRateData.swift      # HR, RHR data models
│   ├── SleepData.swift          # Sleep stages, timing, efficiency
│   ├── WorkoutData.swift        # Workout sessions, HR zones
│   ├── ActivityData.swift       # Steps, energy, distance
│   ├── DailyMetrics.swift       # Aggregated daily snapshot
│   ├── Baseline.swift           # Rolling baselines
│   ├── UserProfile.swift        # [Session 4] User name + HealthKit characteristics
│   ├── Goal.swift               # [Session 4] Habit goals with streak tracking
│   ├── DetectedPattern.swift    # [Session 4] Correlation-based patterns
│   └── WeeklyReport.swift       # [Session 4] Weekly summary reports
│
├── Services/
│   ├── HealthKit/
│   │   ├── HealthKitManager.swift  # + fetchUserCharacteristics()
│   │   ├── HKQueryBuilders.swift
│   │   └── HKDataMappers.swift
│   ├── Calculations/
│   │   ├── Tier1Calculator.swift
│   │   ├── Tier2Calculator.swift
│   │   ├── BaselineEngine.swift
│   │   ├── RecoveryScoreEngine.swift
│   │   └── StrainScoreEngine.swift
│   ├── Persistence/
│   │   ├── LocalStore.swift
│   │   └── ExportService.swift
│   ├── DataQuality/
│   │   └── GapDetector.swift
│   ├── Habits/                  # [Session 4]
│   │   └── PatternDetector.swift    # Pearson correlation pattern detection
│   └── Notifications/           # [Session 4]
│       └── NotificationManager.swift # Recovery alerts, bedtime reminders
│
├── ViewModels/
│   ├── DashboardViewModel.swift     # + sparkline data, trends
│   ├── TimelineViewModel.swift
│   ├── ExportViewModel.swift
│   └── HabitsViewModel.swift        # [Session 4] Goals, patterns, reports
│
├── Views/
│   ├── Dashboard/
│   │   └── DashboardView.swift      # NavigationStack, tappable cards
│   ├── Profile/
│   │   └── ProfileTensorView.swift  # Real user data, settings link
│   ├── Detail/
│   │   └── MetricDetailView.swift   # Push destination for metrics
│   ├── Timeline/
│   │   ├── TimelineView.swift       # + comparison mode
│   │   └── ComparisonView.swift     # [Session 4] Side-by-side comparison
│   ├── Onboarding/              # [Session 4]
│   │   └── OnboardingView.swift     # Welcome, name, HealthKit flow
│   ├── Habits/                  # [Session 4]
│   │   └── HabitsView.swift         # Patterns, goals, reports tabs
│   ├── Settings/                # [Session 4]
│   │   └── NotificationSettingsView.swift
│   ├── Export/
│   └── Components/
│       ├── SovereignGauge.swift
│       ├── DeepDataCard.swift       # + trend indicator, sparkline slot
│       └── Charts/              # [Session 4]
│           ├── SparklineChart.swift     # Mini 7-day trend line
│           └── MetricLineChart.swift    # Full interactive chart
│
├── Utilities/
│   ├── Theme.swift
│   ├── Constants.swift
│   ├── DateHelpers.swift
│   └── StatisticalHelpers.swift
│
└── Whoops/
    ├── Assets.xcassets/
    └── Whoops.entitlements
```

---

## Key Technical Decisions

### Swift 6 Concurrency
- Project uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
- All ViewModels marked `@MainActor`
- SwiftData `@Model` classes are implicitly `@MainActor`
- Use `nonisolated` for functions that don't need actor isolation

### SwiftData Patterns
```swift
// Model record pattern for JSON storage
@Model
final class DailyMetricsRecord {
    @Attribute(.unique) var date: Date
    var metricsJSON: Data

    @MainActor
    convenience init(date: Date, metrics: DailyMetrics) throws { ... }

    nonisolated func getMetrics() throws -> DailyMetrics { ... }
}

// Predicate gotchas - capture variables first
let recordId = record.id
let predicate = #Predicate<BaselineRecord> { r in
    r.id == recordId  // Use captured variable, not record.id
}

// hasPrefix not supported in predicates - filter in memory
let allRecords = try context.fetch(descriptor)
let filtered = allRecords.filter { $0.id.hasPrefix(prefix) }
```

### Xcode 16 Project Configuration
- Uses `PBXFileSystemSynchronizedRootGroup` for folder sync
- All source folders must be in `fileSystemSynchronizedGroups` array
- Info.plist auto-generated via `GENERATE_INFOPLIST_FILE = YES`
- HealthKit permissions via `INFOPLIST_KEY_NSHealthShareUsageDescription`

### Sovereign Dark Theme (Session 3)
- All UI forced to dark mode via `.preferredColorScheme(.dark)`
- OLED black backgrounds (`#000000`) for battery savings
- Neon accent colors for data visualization (Teal=Recovery, Red=Strain)
- Circular gauge components with shadow glow effects
- Tab-based navigation (Dashboard | Profile)

---

## Backup Location

Original uncorrupted source files: `/Users/saqlainmomin/Whoops/Whoops/`

---

## Next Steps

1. ~~Build and test on device with real HealthKit data~~
2. ~~Polish UI components~~ → Sovereign Dark theme implemented
3. ~~Add sparkline graphs inside `DeepDataCard` components~~ → Session 4
4. ~~Connect `ProfileTensorView` to actual user data persistence~~ → Session 4
5. ~~Implement onboarding flow~~ → Session 4
6. ~~Add habit tracking system~~ → Session 4
7. ~~Add timeline comparison mode~~ → Session 4
8. ~~Implement smart notifications~~ → Session 4
9. Add unit tests for calculators
10. Test Recovery and Strain score calculations with real data
11. Implement haptic feedback on interactions
12. Add widget for home screen (Recovery/Strain at a glance)
13. Add Apple Watch companion app

