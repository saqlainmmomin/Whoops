# Whoops Application Plan

## Objective
- Transform Whoops from a HealthKit-powered health dashboard into a coaching-first application.
- The app should help the user understand:
1. How recovered they are
2. How hard they should push today
3. When they should go to bed tonight
- The app should prioritize actionable guidance over raw metric display.

---

## Phase 1: Define The Product Contract
### Goal
- Decide exactly what the app must tell the user every day.

### Deliverables
1. Define the three canonical outputs:
   - `Recovery`
   - `Strain Target`
   - `Sleep / Bedtime Recommendation`
2. Define what each output means:
   - scale
   - inputs
   - confidence rules
   - explanation format
3. Define the daily verdict format:
   - headline
   - primary blocker
   - recommended action
   - confidence
4. Define what will not be primary:
   - steps
   - calorie gamification
   - broad dashboards
   - low-signal biometrics

### Output Artifact
- `PRODUCT_DECISION_ENGINE.md`

---

## Phase 2: Audit And Consolidate The Domain Logic
### Goal
- Remove duplicated and conflicting logic.

### Current Problems
- Scoring and processing logic is split across multiple ViewModels and services.
- Legacy and newer “Whoop-aligned” logic paths coexist.
- The app does not yet have one clear source of truth.

### Deliverables
1. Audit all current scoring and calculation paths.
2. Identify the canonical formula set.
3. Remove or deprecate legacy score paths.
4. Identify duplicated raw-data processing logic in:
   - `DashboardViewModel`
   - `TimelineViewModel`
   - `ExportViewModel`

### Output Artifact
- `LOGIC_AUDIT.md`

---

## Phase 3: Build A Single Assessment Pipeline
### Goal
- Create one shared engine for the app.

### Target Architecture
1. `HealthKitRepository`
   - Fetches and normalizes HealthKit data
2. `BaselineService`
   - Computes 7-day and 28-day baselines
3. `AssessmentEngine`
   - Computes recovery, strain target, and sleep recommendation
4. `RecommendationEngine`
   - Produces explanation and action text
5. `JournalInsightEngine`
   - Computes behavior correlations later

### Core Model To Introduce
- `DailyAssessment`

### `DailyAssessment` Should Contain
- raw input summary
- baseline summary
- recovery
- strain target
- sleep need
- bedtime recommendation
- primary insight
- recommendation
- confidence
- warnings or missing-data notices

### Success Condition
- All major screens render from a shared assessment model instead of redoing logic independently.

---

## Phase 4: Fix Reliability And Data Trust
### Goal
- Make the app safe to trust.

### Work Items
1. Fix HealthKit permission-state handling.
2. Fix baseline progress logic.
3. Fix trend and weekly computation inconsistencies.
4. Fix async reload race conditions.
5. Remove silent failures where possible.
6. Replace `print`-driven failure handling with surfaced app state.
7. Ensure missing or weak data lowers confidence instead of producing false precision.

### Success Condition
- If data is incomplete, the app explicitly communicates low confidence rather than pretending certainty.

---

## Phase 5: Redesign The Home Experience
### Goal
- Make the app feel like coaching software.

### The Home Screen Should Show
1. Recovery
2. Target strain for today
3. Sleep need or bedtime recommendation
4. One primary insight
5. One action recommendation

### Secondary Detail Can Sit Below
- explanation cards
- supporting metrics
- recent trend context

### Design Principle
- Remove clutter instead of adding more cards.

---

## Phase 6: Build The Sleep Coach
### Goal
- Turn sleep data into action.

### Deliverables
1. Sleep need calculation
2. Sleep debt tracking
3. Wake target support
4. Bedtime recommendation
5. Explanation layer:
   - “You need X hours tonight”
   - “Suggested bedtime: Y”
   - “Main reason: recent sleep debt / recovery suppression / schedule inconsistency”

### Success Condition
- The sleep layer becomes one of the strongest daily feedback loops in the app.

---

## Phase 7: Build The Strain Coach
### Goal
- Turn recovery and recent load into training guidance.

### Deliverables
1. Daily strain target range
2. Overreach and undertraining guardrails
3. Recommendation text for:
   - light day
   - moderate day
   - push day
4. Explanation tied to:
   - recovery
   - recent load
   - sleep
   - HRV and RHR signals
   - confidence

### Success Condition
- The app provides a credible daily training recommendation rather than just reporting completed activity.

---

## Phase 8: Build The Journal System
### Goal
- Let users learn what actually affects them.

### Start With Structured Tags
- alcohol
- late meal
- caffeine late
- hard workout
- travel
- illness
- stress
- supplements
- meditation
- poor sleep environment

### Deliverables
1. Simple structured logging UI
2. Behavior storage model
3. Evidence thresholds
4. Insight generation such as:
   - “Alcohol logged 4 times; next-day recovery averaged 9 points lower”
   - “Late caffeine associated with lower sleep efficiency across 6 entries”
5. Confidence or sample size on every pattern insight

### Important Rule
- Do not overclaim causality.

---

## Phase 9: Testing And Verification
### Goal
- Make the coaching logic defensible.

### Add
1. Unit tests for:
   - baseline logic
   - recovery calculation
   - strain target logic
   - sleep recommendation logic
   - confidence rules
2. Golden-case tests for daily assessment scenarios
3. Preview and fixture states for:
   - high recovery
   - low recovery
   - missing data
   - conflicting signals

### Success Condition
- Recommendation logic can be verified and does not drift silently.

---

## Phase 10: Export, Timeline, And Secondary Surfaces
### Goal
- Make supporting surfaces reinforce the core product rather than distract from it.

### After The Coaching Core Is Stable
1. Rebuild timeline as a supporting explanation tool.
2. Keep export as a utility, not a primary experience.
3. Make trend views answer:
   - what changed
   - why it changed
   - what to do next

---

## Recommended Execution Order
1. Product contract
2. Logic audit
3. Shared assessment pipeline
4. Reliability fixes
5. Home screen redesign
6. Sleep coach
7. Strain coach
8. Journal system
9. Tests
10. Secondary screens cleanup

---

## Definition Of Success
- The app is in the right state when a user can open it in 5 seconds and understand:
1. how recovered they are
2. how hard they should push
3. when they should go to bed
4. why the app believes that
5. how confident it is

- If the app can do that consistently, it has moved beyond a dashboard and become coaching software.
