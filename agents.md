# Whoops iOS Project — Codex Agent Instructions

## Project Context
- App: Whoops — Apple Health analytics for fitness/body recomposition
- Product goal: replicate the usefulness of Whoop's software direction using the best signals available from HealthKit
- Stack: SwiftUI, MVVM, async/await, HealthKit
- Language: Swift 5.9+
- Min target: iOS 17
- No UIKit unless absolutely necessary

---

## Product Intent
- Whoops is not a generic health dashboard.
- Whoops is a daily coaching app.
- The app must turn HealthKit data into clear, actionable guidance.
- Every major screen should help answer:
1. How recovered am I?
2. How hard should I push today?
3. When should I go to bed tonight?
- Raw metrics are secondary to recommendations, explanations, and decisions.
- If a UI element does not help a user make a better daily decision, it should be deprioritized or removed.

---

## Primary Product Outputs
- Recovery, Strain, and Sleep Performance are the canonical outputs.
- The home experience should emphasize:
1. Recovery
2. Today's strain target or coaching recommendation
3. Tonight's sleep need or bedtime recommendation
4. A primary insight
5. A recommended action
- Avoid clutter, step-count gamification, badge systems, and low-signal metrics on primary screens unless explicitly requested.

---

## Architecture Constraints
- Follow MVVM strictly: Views render state, ViewModels coordinate state, services perform domain work.
- Do not duplicate metric-processing logic across multiple ViewModels.
- HealthKit normalization, scoring, baseline computation, and recommendation logic must live in shared services or repositories.
- Views should render assessment-oriented models, not raw HealthKit samples directly.
- Repositories fetch data.
- Engines calculate scores and baselines.
- Recommendation services produce guidance and verdicts.
- Favor a single shared daily assessment pipeline over screen-specific calculation logic.

---

## Decision Engine Rules
- The app should behave like a decision engine, not a reporting layer.
- Every major score should have:
1. Inputs
2. Confidence
3. Explanation
4. Recommendation
- Recommendations must be deterministic and explainable by default.
- Do not introduce ML-based recommendations unless explicitly requested.
- If data quality is weak or missing, the app must say so clearly instead of projecting false certainty.
- Prefer transparent heuristics over opaque scoring.

---

## Journal And Behavior Learning
- The journal is a structured behavior-learning system, not just a free-form notes feature.
- Favor structured inputs first, such as:
1. Alcohol
2. Late meal
3. Caffeine late in the day
4. Hard workout
5. Travel
6. Illness
7. Supplements
8. Meditation
9. Stress
10. Sleep environment changes
- Behavior insights should be surfaced only after repeated evidence over time.
- Correlation-style insights must include sample size or confidence.
- Do not use strong causal language unless it is explicitly justified.
- The goal of the journal is to help users run personal experiments and learn what affects recovery and sleep.

---

## Repo-Specific File Conventions
- Use the existing repo structure unless the user explicitly asks for a reorganization.
- Reusable UI components belong in `Views/Components`.
- Feature-specific screens belong under existing folders such as:
1. `Views/Dashboard`
2. `Views/Profile`
3. `Views/Timeline`
4. `Views/Habits`
5. `Views/Export`
6. `Views/Settings`
7. `Views/Onboarding`
- ViewModels belong in `ViewModels`.
- Domain models belong in `Models`.
- Shared utilities belong in `Utilities`.
- Services belong in `Services`, grouped by responsibility.

---

## SKILL: swiftui_feature_builder
**Trigger:** Any new screen, view, or UI component

**Rules:**
1. Use SwiftUI lifecycle only.
2. Follow MVVM — View owns no business logic.
3. Use `@State`, `@Binding`, `@StateObject`, `@ObservedObject`, and environment values deliberately and correctly.
4. Previews are mandatory for every View.
5. Reuse the existing repo folder structure instead of inventing new top-level UI directories.
6. Primary screens should present verdicts and guidance before deep metric detail.

---

## SKILL: viewmodel_generator
**Trigger:** Any ViewModel creation

**Rules:**
1. Suffix all ViewModels with `ViewModel`.
2. Conform to `ObservableObject`.
3. Use `@Published` for all UI-driving properties.
4. Async data fetching goes in `.task {}` flows, `Task {}` blocks, or equivalent lifecycle-safe entry points.
5. No direct HealthKit calls in ViewModel — go through a Repository or shared service boundary.
6. Do not duplicate processing logic that already exists elsewhere in the repo.
7. Prefer exposing high-level assessment state over raw low-level samples.

---

## SKILL: healthkit_integration
**Trigger:** Any Apple Health data read/write

**Rules:**
1. All HealthKit access should go through a `HealthKitRepository` or a clearly designated repository/service abstraction.
2. Always request permissions before querying.
3. Handle authorization denied, restricted, and unknown states explicitly.
4. Use `HKStatisticsCollectionQuery` for time-series data where appropriate.
5. Surface errors to the ViewModel via `Result`, thrown errors, or typed state.
6. Do not let Views own HealthKit query logic.
7. Normalize HealthKit data once in shared services before consumption by scoring/recommendation logic.

---

## SKILL: scoring_and_recommendation_builder
**Trigger:** Any work involving recovery, strain, sleep scoring, baselines, coaching, or recommendations

**Rules:**
1. Recovery, Strain, and Sleep Performance are the primary product metrics.
2. Every score must expose:
   - inputs
   - confidence
   - explanation
   - recommendation impact
3. Recommendation logic should be deterministic, explainable, and testable.
4. If confidence is low, say so explicitly.
5. Prefer one shared assessment model for daily verdicts.
6. Do not invent health claims unsupported by the available data.

---

## SKILL: journal_insight_builder
**Trigger:** Any feature related to habit logging, patterns, correlation, or behavioral insights

**Rules:**
1. Prefer structured behavior logging over unbounded notes first.
2. Insight generation must be conservative.
3. Surface pattern insights only when there is enough repeated evidence.
4. Include sample size, confidence, or evidence strength in any surfaced pattern.
5. Avoid causal wording unless explicitly justified.

---

## SKILL: ui_preview_and_fix_loop
**Trigger:** After generating any View

**Rules:**
1. Build and check Xcode Previews compile without errors where feasible.
2. If preview fails, diagnose and fix before proceeding.
3. Verify mock data is provided for previews.
4. Check for missing environment objects, model containers, and bindings.
5. Ensure primary screens still communicate the coaching verdict clearly in preview form.

---

## Do Not Build By Default
- Do not add gamification features unless explicitly requested.
- Do not prioritize steps, rings, badges, streaks, or achievement metaphors over recovery guidance.
- Do not expose extra metrics on primary screens unless they materially affect a user decision.
- Do not ship placeholder recommendation logic as if it were real coaching logic.
- Do not add UIKit-based flows when SwiftUI can handle the job.

---

## Failure Handling Constraints
- Do not assume APIs exist — verify against Swift 5.9 and iOS 17 SDK.
- Check compiler errors after meaningful file changes where feasible.
- Do not introduce force unwraps (`!`) without an explicit comment explaining why the invariant is safe.
- If HealthKit permission state is unknown, default to requesting, not assuming.
- If available data is incomplete, prefer graceful degradation and explicit uncertainty messaging.
