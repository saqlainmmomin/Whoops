Here is Claude's plan:
Whoops App Improvement Implementation Plan

 Summary

 Fix strain circle bug, unify color system with score-based colors everywhere, implement 8pt spacing grid, and reduce UI noise.

 ---
 Phase 1: Strain Circle Bug Fix

 Root Cause

 SovereignGauge.swift:36 sets type.max = 21 for strain instead of 100. Since strain scores are 0-100, any score >21 results in 100% fill.

 Fix

 File: /Users/saqlainmomin/Desktop/Whoops/Views/Components/SovereignGauge.swift

 Change line 36:
 case .strain: return 21  // Bug
 to:
 case .strain: return 100  // Fixed

 ---
 Phase 2: Color Consistency (Score-Based Everywhere)

 Current State

 - Dashboard gauges: Fixed neon colors
 - Detail views: Score-based (red/yellow/green for recovery, blue/orange/red for strain)
 - Timeline views: Inconsistent mix

 Solution

 Add centralized color functions to Theme.swift and update all components to use them.

 Files to Modify

 1. /Users/saqlainmomin/Desktop/Whoops/Utilities/Theme.swift
   - Add Theme.Colors.recovery(score:) function
   - Add Theme.Colors.strain(score:) function
   - Add corresponding gradient functions
 2. /Users/saqlainmomin/Desktop/Whoops/Views/Components/SovereignGauge.swift
   - Accept score parameter for color calculation
   - Use Theme.Colors.recovery(score:) / Theme.Colors.strain(score:)
 3. /Users/saqlainmomin/Desktop/Whoops/Views/Detail/MetricDetailView.swift
   - Replace local recoveryColor() and strainColor() with Theme functions
 4. /Users/saqlainmomin/Desktop/Whoops/Views/Dashboard/RecoveryCard.swift
   - Replace local scoreColor with Theme function
 5. /Users/saqlainmomin/Desktop/Whoops/Views/Dashboard/StrainCard.swift
   - Replace local scoreColor with Theme function
 6. /Users/saqlainmomin/Desktop/Whoops/Views/Timeline/TimelineView.swift
   - Replace local color functions with Theme functions
 7. /Users/saqlainmomin/Desktop/Whoops/Views/Timeline/ComparisonView.swift
   - Replace local color functions with Theme functions

 Color Definitions

 // Recovery: red (0-33), yellow (34-66), green (67-100)
 static func recovery(score: Int) -> Color {
     switch score {
     case 0...33: return neonRed
     case 34...66: return neonGold
     default: return neonGreen
     }
 }

 // Strain: blue (0-33), orange (34-66), red (67-100)
 static func strain(score: Int) -> Color {
     switch score {
     case 0...33: return Color(hex: "00BFFF")  // Neon blue
     case 34...66: return neonGold
     default: return neonRed
     }
 }

 ---
 Phase 3: Spacing System (8pt Grid)

 Spacing Scale

 enum Spacing {
     static let xs: CGFloat = 4    // Tight spacing
     static let sm: CGFloat = 8    // Small elements
     static let md: CGFloat = 16   // Standard padding
     static let lg: CGFloat = 24   // Section gaps
     static let xl: CGFloat = 32   // Major sections
 }

 Files to Modify

 1. /Users/saqlainmomin/Desktop/Whoops/Utilities/Theme.swift
   - Add Theme.Spacing enum with standardized values
 2. /Users/saqlainmomin/Desktop/Whoops/Views/Dashboard/DashboardView.swift
   - Replace spacing: 30 → spacing: Theme.Spacing.xl
   - Replace spacing: 20 → spacing: Theme.Spacing.lg
   - Replace spacing: 16 → spacing: Theme.Spacing.md
 3. /Users/saqlainmomin/Desktop/Whoops/Views/Components/DeepDataCard.swift
   - Replace spacing: 12 → spacing: Theme.Spacing.md
   - Replace padding(16) → padding(Theme.Spacing.md)
 4. /Users/saqlainmomin/Desktop/Whoops/Views/Detail/MetricDetailView.swift
   - Standardize all spacing values to 8pt grid

 ---
 Phase 4: Signal-to-Noise Reduction

 Elements to Remove

 1. DeepDataCard.swift
   - Line 46-48: Decorative capsule dot (serves no data purpose)
   - Line 65-68: Chevron hint (redundant with NavigationLink behavior)
   - Line 77-80: Border overlay stroke (decorative, not functional)
 2. MetricDetailView.swift
   - Lines 277-288: "About HRV" educational panel (move to onboarding/help)
   - Reduce verbose category descriptions
 3. FormulaCard.swift
   - Consider collapsed by default (currently expands on tap - keep as is)
 4. InputBreakdown.swift
   - Line 409: Remove "Weight: X%" redundant label (weight visible in visual)
   - Line 421: Remove "Raw: X" if not actionable

 Keep

 - Trend indicators (actionable data)
 - Sparkline charts (data visualization)
 - Baseline comparisons (actionable insight)
 - Score components (explains the number)

 ---
 Implementation Order

 1. Fix strain circle (5 min) - immediate bug fix
 2. Add Theme color functions (10 min) - foundation
 3. Update SovereignGauge for score-based colors (10 min)
 4. Update all other color usages (20 min)
 5. Add Theme.Spacing constants (5 min)
 6. Apply spacing to DashboardView (15 min)
 7. Apply spacing to detail views (15 min)
 8. Remove decorative elements (15 min)

 ---
 Verification

 1. Strain Circle: Create strain scores of 10, 50, 100 and verify circle fills at 10%, 50%, 100%
 2. Colors:
   - Recovery score 20 → red gauge
   - Recovery score 50 → yellow/gold gauge
   - Recovery score 80 → green gauge
   - Same logic for strain (blue/gold/red)
 3. Spacing: Visual inspection that all spacing follows 8pt increments
 4. Signal Reduction: Confirm removed elements don't affect functionality

 ---
 Files Modified (Summary)
 ┌─────────────────────────────────┬───────────────────────────────────────────────┐
 │              File               │                    Changes                    │
 ├─────────────────────────────────┼───────────────────────────────────────────────┤
 │ Utilities/Theme.swift           │ Add color functions, spacing constants        │
 ├─────────────────────────────────┼───────────────────────────────────────────────┤
 │ Components/SovereignGauge.swift │ Fix max value, use score-based colors         │
 ├─────────────────────────────────┼───────────────────────────────────────────────┤
 │ Components/DeepDataCard.swift   │ Apply spacing, remove decorative elements     │
 ├─────────────────────────────────┼───────────────────────────────────────────────┤
 │ Dashboard/DashboardView.swift   │ Apply spacing constants                       │
 ├─────────────────────────────────┼───────────────────────────────────────────────┤
 │ Dashboard/RecoveryCard.swift    │ Use Theme color function                      │
 ├─────────────────────────────────┼───────────────────────────────────────────────┤
 │ Dashboard/StrainCard.swift      │ Use Theme color function                      │
 ├─────────────────────────────────┼───────────────────────────────────────────────┤
 │ Detail/MetricDetailView.swift   │ Use Theme colors, apply spacing, reduce noise │
 ├─────────────────────────────────┼───────────────────────────────────────────────┤
 │ Detail/InputBreakdown.swift     │ Simplify labels                               │
 ├─────────────────────────────────┼───────────────────────────────────────────────┤
 │ Timeline/TimelineView.swift     │ Use Theme color functions                     │
 ├─────────────────────────────────┼───────────────────────────────────────────────┤
 │ Timeline/ComparisonView.swift   │ Use Theme color functions                     │
 └─────────────────────────────────┴───────────────────────────────────────────────┘