# Whoops - Claude Code Context

## Project Summary

iOS health analytics app replicating Whoop metrics using Apple HealthKit. Built with SwiftUI + SwiftData for iOS 17.6+. All data stays on-device.

## Quick Reference

### Build Target
- **Platform:** iOS 17.6+
- **Swift Version:** 5.0 with Swift 6 concurrency features
- **Xcode:** 16+ (uses PBXFileSystemSynchronizedRootGroup)

### Key Files
| Purpose | File |
|---------|------|
| App entry | `App/WhoopsApp.swift` |
| Main data model | `Models/DailyMetrics.swift` |
| Baselines | `Models/Baseline.swift` |
| User profile | `Models/UserProfile.swift` |
| Goals & habits | `Models/Goal.swift` |
| HealthKit queries | `Services/HealthKit/HealthKitManager.swift` |
| Data persistence | `Services/Persistence/LocalStore.swift` |
| Recovery algorithm | `Services/Calculations/RecoveryScoreEngine.swift` |
| Strain algorithm | `Services/Calculations/StrainScoreEngine.swift` |
| Pattern detection | `Services/Habits/PatternDetector.swift` |
| Notifications | `Services/Notifications/NotificationManager.swift` |
| Main UI | `Views/Dashboard/DashboardView.swift` |
| Onboarding | `Views/Onboarding/OnboardingView.swift` |
| Habits UI | `Views/Habits/HabitsView.swift` |
| Charts | `Views/Components/Charts/SparklineChart.swift` |

### Backup Location
Original source files: `/Users/saqlainmomin/Whoops/Whoops/`

## Critical Patterns

### Swift 6 Actor Isolation
This project uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. When working with Codable structs:

```swift
// CORRECT - use @preconcurrency for Codable extension
struct MyModel: Sendable {
    // properties
}
extension MyModel: @preconcurrency Codable {}

// In @Model classes
@MainActor
convenience init(...) throws { }  // For encoding

nonisolated func getData() throws -> MyModel { }  // For decoding
```

### SwiftData Predicates
```swift
// CORRECT - capture variable before predicate
let searchId = someValue
let predicate = #Predicate<Record> { r in
    r.id == searchId
}

// WRONG - using external variable directly
let predicate = #Predicate<Record> { r in
    r.id == record.id  // Will fail
}

// hasPrefix/startsWith NOT supported - filter in memory
let all = try context.fetch(descriptor)
let filtered = all.filter { $0.id.hasPrefix(prefix) }
```

### Required Imports
Files using `@Published`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject` need:
```swift
import Combine
```

## Project Structure

```
Whoops/
├── App/           # App entry, global state
├── Models/        # Data models (DailyMetrics, Baseline, UserProfile, Goal, etc.)
├── Services/
│   ├── HealthKit/      # HK queries and mapping
│   ├── Calculations/   # Tier 1, 2, 3 calculators
│   ├── Persistence/    # SwiftData operations
│   ├── DataQuality/    # Gap detection
│   ├── Habits/         # Pattern detection
│   └── Notifications/  # Smart notifications
├── ViewModels/    # Observable view models
├── Views/
│   ├── Dashboard/      # Main dashboard
│   ├── Timeline/       # Historical data + comparison
│   ├── Habits/         # Goals, patterns, reports
│   ├── Onboarding/     # First-launch flow
│   ├── Settings/       # Notification preferences
│   ├── Components/     # Reusable UI (gauges, cards, charts)
│   └── ...
├── Utilities/     # Helpers, constants
└── Whoops/        # Assets, entitlements
```

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "Main actor-isolated conformance" error | Use `@preconcurrency Codable` extension |
| "Undefined symbol: _main" | Ensure App folder is in `fileSystemSynchronizedGroups` |
| Info.plist duplicate output | Remove Info.plist file, use auto-generation |
| Predicate compilation error | Capture variables before #Predicate closure |
| Missing Combine module | Add `import Combine` to file |
| ObservableObject not conforming | Add `import Combine` to file |
| NavigationLink not navigating | Use `.buttonStyle(PlainButtonStyle())` |

## Metric Tiers

1. **Tier 1 (Factual):** Direct from HealthKit - HR, HRV, sleep duration, steps
2. **Tier 2 (Deterministic):** Calculated - load ratios, z-scores, sleep debt
3. **Tier 3 (Inferred):** Scores - Recovery (0-100), Strain (0-100)

## Session 4 Patterns (Jan 14, 2025)

### NavigationStack with Destination Router
```swift
NavigationStack {
    ScrollView { ... }
        .navigationDestination(for: MetricType.self) { type in
            MetricDetailView(metricType: type, ...)
        }
}

// Tappable cards
NavigationLink(value: MetricType.hrv) {
    DeepDataCard(...)
}
.buttonStyle(PlainButtonStyle())
```

### NotificationManager Singleton
```swift
@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @AppStorage("notifications.lowRecoveryAlert") var lowRecoveryAlertEnabled = true
    // ... other @AppStorage preferences
}
```

### Pattern Detection (Pearson Correlation)
```swift
private func calculateCorrelation(x: [Double], y: [Double]) -> Double {
    let n = Double(x.count)
    let sumX = x.reduce(0, +)
    let sumY = y.reduce(0, +)
    let sumXY = zip(x, y).map(*).reduce(0, +)
    let sumX2 = x.map { $0 * $0 }.reduce(0, +)
    let sumY2 = y.map { $0 * $0 }.reduce(0, +)

    let numerator = n * sumXY - sumX * sumY
    let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
    return denominator != 0 ? numerator / denominator : 0
}
```

### Tab Structure (4 tabs)
1. **Dashboard** - Today's metrics with tappable cards
2. **Timeline** - Historical data with comparison mode
3. **Habits** - Patterns, goals, weekly reports
4. **Profile** - User settings, notifications, data export

## Development History

See `DEVELOPMENT_CONTEXT.md` for full timeline and detailed technical decisions.
