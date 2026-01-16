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

**Technical Patterns Introduced:**
- NavigationStack with `navigationDestination(for: MetricType.self)` router
- Comparison mode with multi-selection state (`compareFirstDay`, `compareSecondDay`)
- Pattern detection using Pearson correlation
- NotificationManager singleton with `@AppStorage` preferences
- Swift Charts framework for SparklineChart and MetricLineChart

### Session 5 (Jan 16, 2025) - Brutalist/Industrial UI Redesign
**Major Pivot:** Complete visual overhaul from neon "Sovereign" theme to stark Brutalist/Industrial aesthetic

**Design Philosophy:**
- Heavy typography, stark black/white contrasts
- Bold geometric forms, raw edges
- No rounded corners, no soft shadows, no gradients
- ONE sharp accent color (Rust Red) for critical data
- Visible structure, intentional roughness

**Theme System Overhaul (`Theme.swift`):**

| Before (Sovereign) | After (Brutalist) |
|-------------------|-------------------|
| `sovereignBlack` (#000000) | `void` (pure black) |
| `neonTeal` (#00E5FF) | `bone` (pure white) |
| `neonRed` (#FF003C) | `rust` (#FF2D00) |
| `neonGreen` (#00FF94) | Removed - binary states only |
| `neonGold` (#FFD700) | `chalk` (#888888) |
| `panelGray` (#1C1C1E) | `concrete` (#0A0A0A), `steel` (#1A1A1A) |
| Gradients | Flat colors only |
| Glow effects | No effects |
| 12pt corner radius | 0pt (sharp edges) |

**New Color Tokens:**
```swift
Theme.Colors.void      // #000000 - Primary background (OLED black)
Theme.Colors.concrete  // #0A0A0A - Secondary surface
Theme.Colors.steel     // #1A1A1A - Tertiary/inactive
Theme.Colors.graphite  // #2A2A2A - Borders/dividers
Theme.Colors.bone      // #FFFFFF - Primary text
Theme.Colors.chalk     // #888888 - Secondary text
Theme.Colors.ash       // #555555 - Disabled/inactive
Theme.Colors.rust      // #FF2D00 - Critical accent (THE accent)
```

**Typography Changes:**
```swift
Theme.Fonts.mono(size:)     // SF Mono Bold - all numeric values
Theme.Fonts.display(size:)  // SF Mono Heavy - massive numbers
Theme.Fonts.header(size:)   // SF Pro Bold - section headers
Theme.Fonts.label(size:)    // SF Pro Medium - labels (UPPERCASE + tracking)
```

**Component Transformations:**

| Component | Before | After |
|-----------|--------|-------|
| `SovereignGauge` | Circular ring with neon glow | Horizontal bar meter with tick marks |
| `DeepDataCard` | Rounded cards, subtle backgrounds | Sharp-edged blocks, visible 1px borders |
| `RecoveryCard` | System colors, soft styling | Industrial meters, rust accent for critical |
| `StrainCard` | Gradient fills, rounded corners | Binary color states, hard dividers |

**Dashboard Layout Restructure:**
- **Primary Zone (40%+):** Recovery meter - dominant visual weight
- **Secondary Zone:** Strain + HRV + RHR in compact cells
- **Tertiary Zone:** Sleep + Activity cards with sparklines
- **Hard horizontal dividers** between zones
- **Visible grid structure** throughout

**New View Modifier:**
```swift
.brutalistBorder(_ color: Color = Theme.Colors.graphite, width: CGFloat = 1)
// Applies hard-edged rectangular border, no rounded corners
```

**Files Modified:**

| File | Changes |
|------|---------|
| `Theme.swift` | Complete color/typography overhaul, removed gradients, added `.brutalistBorder()` modifier |
| `SovereignGauge.swift` | Replaced circular gauge with horizontal bar meter |
| `DeepDataCard.swift` | Sharp edges, visible borders, new trend badge styling |
| `DashboardView.swift` | Asymmetric zone-based layout, hard dividers |
| `RecoveryCard.swift` | Industrial styling, component breakdown cells |
| `StrainCard.swift` | Binary color states, tick marks at 33%/67% |
| `TimelineView.swift` | Brutalist day rows, week headers, day detail view |
| `ComparisonView.swift` | Hard-edged comparison blocks, VS divider |
| `MetricDetailView.swift` | Large mono numbers, collapsible formula cards |

**Design Decisions:**
- Accent color: Rust Red (#FF2D00) - industrial urgency
- Typography: SF Mono Bold for all numeric values
- Borders: 1px graphite borders, rust for critical states
- Score states: Binary (normal = bone, critical = rust)
  - Recovery ≤33 = critical
  - Strain ≥67 = critical

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
│   ├── UserProfile.swift        # User name + HealthKit characteristics
│   ├── Goal.swift               # Habit goals with streak tracking
│   ├── DetectedPattern.swift    # Correlation-based patterns
│   └── WeeklyReport.swift       # Weekly summary reports
│
├── Services/
│   ├── HealthKit/
│   │   ├── HealthKitManager.swift
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
│   ├── Habits/
│   │   └── PatternDetector.swift
│   └── Notifications/
│       └── NotificationManager.swift
│
├── ViewModels/
│   ├── DashboardViewModel.swift
│   ├── TimelineViewModel.swift
│   ├── ExportViewModel.swift
│   └── HabitsViewModel.swift
│
├── Views/
│   ├── Dashboard/
│   │   ├── DashboardView.swift      # Brutalist zone-based layout
│   │   ├── RecoveryCard.swift       # Industrial meter styling
│   │   └── StrainCard.swift         # Binary color states
│   ├── Profile/
│   │   └── ProfileTensorView.swift
│   ├── Detail/
│   │   └── MetricDetailView.swift   # Large mono numbers, formula cards
│   ├── Timeline/
│   │   ├── TimelineView.swift       # Brutalist day rows
│   │   └── ComparisonView.swift     # Hard-edged comparison
│   ├── Onboarding/
│   │   └── OnboardingView.swift
│   ├── Habits/
│   │   └── HabitsView.swift
│   ├── Settings/
│   │   └── NotificationSettingsView.swift
│   ├── Export/
│   └── Components/
│       ├── SovereignGauge.swift     # Horizontal bar meter (brutalist)
│       ├── DeepDataCard.swift       # Sharp-edged data blocks
│       └── Charts/
│           ├── SparklineChart.swift
│           └── MetricLineChart.swift
│
├── Utilities/
│   ├── Theme.swift                  # Brutalist design system
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

### Brutalist Design System (Session 5)
- All UI forced to dark mode via `.preferredColorScheme(.dark)`
- OLED black backgrounds (`#000000`) for battery savings
- Single accent color: Rust Red (#FF2D00) for critical states
- No rounded corners - all components use sharp rectangular edges
- No gradients - flat colors only
- No shadow/glow effects - hard borders instead
- Typography: SF Mono Bold for numbers, uppercase labels with letter-spacing
- Binary color states: bone (normal) vs rust (critical)
- Horizontal bar meters replace circular gauges
- Zone-based dashboard layout with hard dividers

---

## Backup Location

Original uncorrupted source files: `/Users/saqlainmomin/Whoops/Whoops/`

---

## Next Steps

1. ~~Build and test on device with real HealthKit data~~
2. ~~Polish UI components~~ → Sovereign Dark theme (Session 3)
3. ~~Add sparkline graphs inside `DeepDataCard` components~~ → Session 4
4. ~~Connect `ProfileTensorView` to actual user data persistence~~ → Session 4
5. ~~Implement onboarding flow~~ → Session 4
6. ~~Add habit tracking system~~ → Session 4
7. ~~Add timeline comparison mode~~ → Session 4
8. ~~Implement smart notifications~~ → Session 4
9. ~~Fix strain circle bug~~ → Session 4.1
10. ~~Unify color system with score-based colors~~ → Session 4.1
11. ~~Implement 8pt spacing grid~~ → Session 4.1
12. ~~Reduce UI noise (remove decorative elements)~~ → Session 4.1
13. ~~Complete UI redesign with brutalist aesthetic~~ → Session 5
14. Apply brutalist styling to remaining views (Onboarding, Habits, Settings, Profile)
15. Add unit tests for calculators
16. Test Recovery and Strain score calculations with real data
17. Implement haptic feedback on interactions
18. Add widget for home screen (Recovery/Strain at a glance)
19. Add Apple Watch companion app
