# Dashboard Redesign Plan: Whoop-Equivalent Experience

## Executive Summary

Your current dashboard presents metrics in a flat, zone-based layout that prioritizes raw values over contextual insight. The Whoop model employs a hierarchical information architecture centered on a primary metric (Recovery), with supporting data arranged to tell a causal story. This plan addresses the systematic gaps between your current implementation and the Whoop standard.

---

## 1. Dashboard-Level Information Architecture

### Current State
`DashboardView.swift` uses a linear vertical stack with 5 zones separated by dividers. All metrics are given roughly equal visual weight below the Recovery gauge. The structure reads as a data dump rather than a narrative.

### Required Changes

**1.1 Introduce Tab-Based Navigation Within Dashboard**
- Add horizontal tab bar: `OVERVIEW | SLEEP | RECOVERY | STRAIN`
- Each tab presents a focused view with appropriate depth
- The OVERVIEW tab becomes the current dashboard (redesigned)
- This matches Whoop's "TODAY" screen pattern and reduces cognitive load by allowing progressive disclosure

**Why**: Whoop separates summary from detail at the dashboard level itself. Users can get the headline (OVERVIEW) or dive into a single domain without leaving the main screen.

**1.2 Establish Clear Metric Hierarchy**
- **Hero Zone (60% of above-fold space)**: Recovery score as primary metric
- **Context Zone**: Supporting metrics that explain the hero metric
- **Activity Zone**: What happened today (sleep session, activities, strain events)
- **Guidance Zone**: Actionable insight based on current state

**Why**: Whoop's dashboard answers "How am I doing?" (Recovery), "Why?" (supporting metrics), "What did I do?" (activities), and "What should I do?" (recommendations) in sequence.

---

## 2. Primary Metric Presentation (Recovery)

### Current State
`SovereignGauge` renders a horizontal segmented bar with the score at right. The component (`Views/Components/SovereignGauge.swift`) emphasizes the brutalist aesthetic but sacrifices the visual dominance needed for the primary metric.

### Required Changes

**2.1 Replace Horizontal Bar with Circular Progress Ring**
- Create a new `RecoveryRing` component
- Large circular arc (minimum 200pt diameter) with recovery color fill
- Score displayed as massive centered typography (72pt minimum)
- Percentage symbol as subscript
- Category label below ("MODERATE", "PEAK RECOVERY", etc.)

**Why**: Whoop uses circular gauges exclusively for primary metrics because:
1. The ring completion provides instant visual parsing of magnitude
2. Center space allows for large score display
3. The form factor naturally commands visual hierarchy
4. Interior ring space can host secondary info without clutter

**2.2 Add Recovery Explanation Banner**
- Position below the ring
- Dynamic text based on recovery score and contributing factors
- Examples: "ELEVATED HRV — Your HRV is 12% higher than usual. Your nervous system is ready to handle stress."
- Use stylized logo icon as leading indicator

**Why**: Whoop never shows a score without explaining why. This transforms data display into decision support.

**2.3 Add Optimal Strain Target**
- Display recommended strain target based on recovery
- Format: "Your optimal Strain target is 12.7"
- Position within the Recovery context area

**Why**: This closes the loop between recovery (input state) and recommended activity (output action), which is the core value proposition.

---

## 3. Secondary Metric Display (Strain, HRV, RHR)

### Current State
`secondaryDataSection` in `DashboardView.swift` renders Strain as a mini gauge and HRV/RHR as `BrutalistDataCell` components. All three are given equal width in an HStack.

### Required Changes

**3.1 Elevate Strain to Semi-Primary Status**
- Create `StrainArc` component: partial circular arc positioned adjacent to Recovery ring
- Display strain score (0-21 scale or 0-100 normalized)
- Show accumulating strain through the day with visual fill
- Add "START ACTIVITY" call-to-action link

**Why**: Whoop positions Strain as the counterweight to Recovery. The visual pairing (Recovery ring + Strain arc) creates a natural tension that guides decision-making.

**3.2 Position HRV and RHR as Recovery Ring Annotations**
- Place HRV value to the left of the Recovery ring
- Place RHR value to the right of the Recovery ring
- Format: value + unit (e.g., "108 HRV", "48 RHR")
- Subtle secondary typography (12-14pt)

**Why**: Whoop arranges supporting metrics spatially around the primary metric to show relationship. HRV and RHR directly influence Recovery, so proximity reinforces causality.

**3.3 Add Baseline Reference to All Secondary Metrics**
- Each metric should show deviation from baseline
- Format: arrow indicator + "↑ 12%" or "↓ 5 bpm from avg"
- Color code: green for favorable, red/orange for concerning

**Why**: Raw values without reference points are meaningless. Your `Baseline` model already calculates z-scores and deviations—expose them.

---

## 4. Tertiary Section Redesign (Sleep, Activity)

### Current State
`tertiaryDataSection` uses two `DeepDataCard` components for Sleep and Active Calories. Cards include sparklines but no context.

### Required Changes

**4.1 Transform Sleep Card into "Today's Activities" Section**
- Rename section header to "TODAY'S ACTIVITIES"
- Show sleep session as a horizontal bar: moon icon + "6:18" duration + "SLEEP" label + time range "7:46 AM – 12:50 PM"
- Add completed workouts below in same format
- Each item is tappable for detail

**Why**: Whoop presents sleep as an event (something that happened) rather than just a metric. This reinforces temporal awareness.

**4.2 Create Sleep Performance Sub-Card (for SLEEP tab)**
- Large circular gauge showing Sleep Performance percentage
- Sub-metrics list with segmented progress bars:
  - Hours vs. Needed
  - Sleep Consistency
  - Sleep Efficiency
  - High Sleep Stress
- Each sub-metric shows Poor/Sufficient/Optimal state
- Contextual text explaining sleep performance

**Why**: Whoop decomposes sleep into actionable sub-metrics. Your `DailySleepSummary` model contains efficiency, stages, and timing—surface this breakdown.

**4.3 Add "Hours vs. Need" Metric**
- Calculate sleep need based on strain and baseline
- Display: actual hours (white) vs. needed hours (green)
- Format: "7:06 / 9:17"
- This requires adding sleep need calculation to `Tier2Calculator`

**Why**: This is Whoop's most actionable sleep insight—it tells users whether they got enough sleep relative to their recovery demands.

---

## 5. Chart Types and Data Encodings

### Current State
`SparklineChart` renders a simple line with area fill. No axes, no labels, no baseline reference, no interaction.

### Required Changes

**5.1 Create Weekly Sleep Timing Chart (Vertical Bars)**
- X-axis: days of week (Mon-Sun)
- Y-axis: time of day (10pm-10am)
- Each day shows a vertical bar from bedtime to wake time
- Hover/tap shows exact times
- Highlight inconsistency visually (bars at different positions)

**Why**: Whoop uses this chart specifically for sleep consistency visualization. It communicates circadian rhythm health at a glance.

**5.2 Create 7-Day Trend Chart with Baseline Band**
- Line chart with date x-axis
- Add shaded band showing ±1 standard deviation from baseline
- Current day highlighted with larger point
- Show if current value is within/outside normal range

**Why**: This transforms "here's your HRV" into "here's your HRV vs. your normal range," which is the insight users actually need.

**5.3 Add Mini Distribution Charts for Sub-Metrics**
- 3-segment horizontal bar (Poor | Sufficient | Optimal)
- Current value indicated by position marker
- Used for Sleep Performance sub-metrics
- Encode quality visually without requiring numerical interpretation

**Why**: Whoop uses these for rapid quality assessment. Segmented bars work better than percentages for qualitative judgments.

**5.4 Create Strain Accumulation Chart**
- Hour-by-hour strain buildup through the day
- X-axis: time (6am-12am)
- Y-axis: cumulative strain (0-21)
- Shows strain events (workouts) as step increases

**Why**: Strain is inherently cumulative. This visualization shows how the day's activities built up load.

---

## 6. Daily Snapshot vs. Historical Trend Separation

### Current State
The dashboard shows only today's values. `TimelineView` shows historical data but in a list format. There's no visual connection between today and recent history on the main dashboard.

### Required Changes

**6.1 Add "7-Day Average" Footer to Primary Metrics**
- Below Recovery ring: "7D AVG: 68"
- Below Strain display: "7D AVG: 11.2"
- Position as subtle secondary information

**Why**: Single-day values fluctuate. The average provides stability reference.

**6.2 Create "vs. Previous 30 Days" Section on Detail Views**
- When tapping Recovery, show "RECOVERY STATISTICS vs PREVIOUS 30 DAYS"
- Display sparkline for each component (HRV, RHR, Sleep)
- Show trend direction for each

**Why**: Whoop's Recovery detail screen uses this exact framing. It answers "Is this normal for me?"

**6.3 Add Week-Over-Week Comparison Card**
- "This week vs. last week" summary
- Key metrics: Avg Recovery, Total Strain, Avg Sleep
- Show delta with direction indicator

**Why**: Weekly comparison provides the right time horizon for fitness/recovery trend detection.

---

## 7. Baseline, Range, and Deviation Display

### Current State
Your `Baseline` model calculates averages, standard deviations, z-scores, and deviations. These are available in `DashboardViewModel` but only partially surfaced (trends).

### Required Changes

**7.1 Add Personal Range Indicators to All Metrics**
- Show individual normal range: "Your range: 42-58ms" for HRV
- Indicate if current value is within range
- Use `hrvStdDev`, `restingHRStdDev` from `Baseline` model

**Why**: Whoop's "within range" concept is central to their Health Monitor. You have the data; surface it.

**7.2 Create Health Monitor Section**
- "5/5 METRICS WITHIN RANGE" or "2/5 METRICS OUTSIDE RANGE"
- List which metrics are flagged
- Positioned at bottom of OVERVIEW tab

**Why**: This is Whoop's summary diagnostic. It converts multiple metric evaluations into a single checkup result.

**7.3 Implement Deviation Highlighting**
- Metrics outside 1.5 standard deviations get visual emphasis (border, color)
- Use `hrvZScore()` and `rhrDeviation()` methods already in `Baseline`
- Current `brutalistBorder(isCritical:)` pattern can be extended

**Why**: Abnormal values deserve attention; normal values don't. The UI should reflect this.

---

## 8. Attention Guidance and Decision Enablement

### Current State
`insightSection` displays a single status message from `RecoveryCategory.description`. It's static and generic.

### Required Changes

**8.1 Implement Dynamic Insight Engine**
- Generate contextual insights based on data patterns:
  - "Your sleep was 1.5 hours below your need"
  - "Your HRV is 15% above baseline—good day for high intensity"
  - "RHR elevated 5bpm—consider recovery day"
- Prioritize most actionable insight
- Use `PatternDetector` service for correlation-based insights

**Why**: Whoop's "PEAK RECOVERY" and "ELEVATED HRV" callouts are generated from data, not category buckets. They tell users what's notable and what to do about it.

**8.2 Add Strain Recommendation System**
- Calculate optimal strain target based on recovery score
- Formula: `targetStrain = baseStrain * (recoveryScore / 100) * modifier`
- Display as actionable guidance: "Aim for 8-12 strain today"

**Why**: This closes the loop from assessment (Recovery) to action (Strain target).

**8.3 Implement "Learn More" Deep Links**
- Each insight should link to relevant education or detail view
- "LEARN MORE →" pattern
- Link to detail views with expanded context

**Why**: Insights are more valuable when users can explore the reasoning.

---

## 9. Card Anatomy Changes (Summary vs. Detail States)

### Current State
`DeepDataCard` has one display mode. `MetricDetailView` is a separate screen. There's no intermediate expansion state.

### Required Changes

**9.1 Create Expandable Card Pattern**
- Tap card → expands in-place to show additional context
- Second tap → navigates to full detail view
- Or: tap card → shows expanded overlay with "See Full Detail" option

**Why**: Whoop uses progressive disclosure. The dashboard card is state 1, the expanded view is state 2, the full detail is state 3.

**9.2 Define Card Summary State (Dashboard)**
- Primary value only
- Trend indicator
- No charts in summary state
- Minimal footprint

**9.3 Define Card Expanded State (Overlay/Inline)**
- Primary value + unit
- 7-day sparkline
- Baseline comparison
- One-line insight
- "View Details" link

**9.4 Define Card Detail State (Full Screen)**
- Full historical chart with interaction
- Component breakdown
- Formula explanation (already have `FormulaCard`)
- Related metrics section

**Why**: This three-state model matches Whoop's information architecture and reduces dashboard clutter while maintaining access to depth.

---

## 10. Specific Component Changes Summary

| Current Component | Change Required | Rationale |
|---|---|---|
| `SovereignGauge` | Replace with `RecoveryRing` (circular) | Visual dominance, central placement |
| `StrainCard` | Replace with `StrainArc` (partial circle) | Pair visually with Recovery |
| `DeepDataCard` | Add expandable state, baseline reference | Progressive disclosure |
| `BrutalistDataCell` | Add deviation indicator | Context for raw values |
| `SparklineChart` | Add baseline band, axes option, interaction | Meaningful trend display |
| `MetricDetailView` | Add "vs. 30-day" section, sub-metric charts | Historical context |
| `insightSection` | Replace with dynamic insight engine | Actionable guidance |

---

## 11. Tab Content Specification

### OVERVIEW Tab
- Hero: Recovery Ring with score, category, explanation
- Satellite: Strain Arc, HRV, RHR (positioned around ring)
- Activities: Sleep session + workouts as event list
- Health: "X/5 metrics within range" summary
- Insight: Primary actionable recommendation

### SLEEP Tab
- Hero: Sleep Performance circular gauge
- Sub-metrics: Hours vs. Need, Consistency, Efficiency, Stress
- Chart: Weekly sleep timing (vertical bars)
- Summary: 7-day averages (Performance, Hours vs. Need, Time in Bed)

### RECOVERY Tab
- Hero: Recovery Ring (same as OVERVIEW but larger)
- Explanation: Dynamic insight about recovery state
- Statistics: "vs. Previous 30 Days" with HRV sparkline
- Components: Component contribution breakdown

### STRAIN Tab
- Hero: Strain score with daily accumulation chart
- Activities: Workout list with individual strain contributions
- Chart: Hour-by-hour strain buildup
- Target: Recommended vs. actual strain comparison

---

## 12. Data Model Implications

Your data models are well-structured for this transformation. Key observations:

- `DailyMetrics` contains all Tier 1/2/3 data needed
- `Baseline` provides z-score and deviation methods
- `DashboardViewModel` already calculates trends and sparkline data
- `RecoveryScore` and `StrainScore` have component breakdowns

**Required Additions:**
1. Sleep need calculation (in `Tier2Calculator` or new service)
2. Optimal strain target calculation (in `StrainScoreEngine`)
3. Health Monitor metric evaluation (new method in `BaselineEngine`)
4. Dynamic insight generation (extension to `PatternDetector`)

---

## 13. New Components to Create

### Views/Components/
- `RecoveryRing.swift` - Circular progress ring for Recovery score
- `StrainArc.swift` - Partial arc for Strain display
- `SleepPerformanceGauge.swift` - Circular gauge for Sleep Performance
- `SegmentedProgressBar.swift` - Poor/Sufficient/Optimal indicator
- `SleepTimingChart.swift` - Weekly vertical bar chart for sleep consistency
- `BaselineBandChart.swift` - Line chart with ±1 std dev band
- `StrainAccumulationChart.swift` - Hour-by-hour strain buildup
- `HealthMonitorBadge.swift` - "X/5 metrics within range" component
- `ActivityEventRow.swift` - Sleep/workout event display row
- `InsightBanner.swift` - Dynamic insight with icon and explanation

### Views/Dashboard/
- `DashboardTabView.swift` - Tab container for OVERVIEW/SLEEP/RECOVERY/STRAIN
- `OverviewTab.swift` - Main overview content
- `SleepTab.swift` - Sleep-focused content
- `RecoveryTab.swift` - Recovery detail content
- `StrainTab.swift` - Strain detail content

### Services/Calculations/
- `SleepNeedCalculator.swift` - Calculate sleep need based on strain/baseline
- `StrainTargetCalculator.swift` - Calculate optimal strain target
- `HealthMonitorEngine.swift` - Evaluate metrics against personal ranges

### Services/Insights/
- `InsightGenerator.swift` - Generate dynamic contextual insights
- `InsightPrioritizer.swift` - Rank insights by actionability

---

## 14. Implementation Priority Order

### Phase 1: Core Visual Hierarchy
1. Create `RecoveryRing` component
2. Refactor `DashboardView` hero zone
3. Position HRV/RHR around Recovery ring
4. Add `StrainArc` component

### Phase 2: Tab Architecture
5. Create `DashboardTabView` container
6. Implement OVERVIEW tab with current content
7. Create SLEEP tab with Sleep Performance gauge
8. Create RECOVERY tab with detail view
9. Create STRAIN tab with accumulation chart

### Phase 3: Baseline Integration
10. Add deviation indicators to all metrics
11. Create `HealthMonitorBadge`
12. Implement personal range display
13. Add "7-Day Average" footers

### Phase 4: Charts and Visualization
14. Create `SleepTimingChart`
15. Create `BaselineBandChart`
16. Create `SegmentedProgressBar`
17. Enhance `SparklineChart` with interaction

### Phase 5: Insights and Recommendations
18. Create `InsightGenerator` service
19. Create `InsightBanner` component
20. Add strain target calculation
21. Add sleep need calculation

### Phase 6: Polish and Integration
22. Implement expandable card states
23. Add "Today's Activities" section
24. Connect all navigation paths
25. Performance optimization

---

This plan provides the systematic changes required to achieve Whoop-equivalent information architecture, metric prioritization, temporal insight, and decision support. The current brutalist aesthetic can be retained while implementing these structural improvements.
