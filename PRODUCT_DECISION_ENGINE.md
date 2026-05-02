# Whoops Product Decision Engine

## Purpose
- Whoops is a daily coaching app, not a broad health dashboard.
- The product must answer three questions every day:
  1. How recovered am I?
  2. How hard should I push today?
  3. When should I go to bed tonight?
- All primary outputs must be deterministic, explainable, and explicit about uncertainty.

## Canonical Daily Outputs

### 1. Recovery
- Scale: `0...100`
- Meaning: current physiological readiness to absorb training stress today
- Primary inputs:
  - HRV versus baseline
  - Resting heart rate versus baseline
  - Last night sleep sufficiency versus baseline sleep need
  - Sleep disruption if available
- Supporting context:
  - baseline quality
  - last 7 days trend context
  - current data quality
- Confidence rules:
  - `High`: usable HRV, RHR, and sleep inputs with strong daily coverage and a sufficient baseline
  - `Medium`: one major input is weak or baseline quality is limited
  - `Low`: multiple key inputs missing, sparse, or baseline quality insufficient
- Explanation format:
  - headline verdict
  - 2-4 concrete drivers
  - one blocker if recovery is suppressed
  - one action recommendation

### 2. Strain Target
- Scale: target range on `0...21`
- Meaning: recommended training load capacity for today, not just strain already completed
- Primary inputs:
  - current recovery
  - recent load and load ratio
  - recent sleep sufficiency
  - current data confidence
- Rules:
  - low recovery narrows the allowed range
  - high recent load reduces aggressive targets even when recovery is decent
  - low confidence narrows the recommendation and defaults conservative
- Explanation format:
  - target range
  - training day type: `light`, `moderate`, or `push`
  - why that target was chosen
  - one practical training recommendation

### 3. Sleep / Bedtime Recommendation
- Scale:
  - sleep need in hours
  - recommended bedtime as a concrete clock time when enough schedule context exists
- Meaning: how much sleep the user needs tonight to support recovery tomorrow
- Primary inputs:
  - baseline sleep need or baseline sleep duration
  - current sleep debt
  - recovery suppression
  - schedule consistency and typical wake time when available
- Rules:
  - bedtime guidance should only be shown as precise if wake schedule context is credible
  - if schedule context is weak, recommend sleep need first and state why bedtime is approximate
  - elevated sleep debt or suppressed recovery should increase tonight's need conservatively
- Explanation format:
  - sleep need
  - suggested bedtime if available
  - main reason
  - one tonight action

## Daily Verdict Format
- `headline`: the main coaching verdict for today
- `primary blocker`: the biggest limiting factor, or `none` if no blocker
- `recommended action`: one behavior or training action
- `confidence`: `Low`, `Medium`, or `High`
- `warnings`: data gaps or weak-baseline notices

## Confidence Contract
- Confidence applies to every major score and to the overall daily verdict.
- Confidence must degrade when:
  - HRV is missing or sparse
  - resting HR is missing
  - sleep data is incomplete
  - baseline sample size is limited
  - activity data is too weak to support a precise strain target
- Low confidence must change the language:
  - use conservative recommendations
  - avoid precise claims
  - name the missing signal directly

## What Is Primary On Home
- Recovery
- Today’s strain target
- Tonight’s sleep need or bedtime recommendation
- One primary insight
- One recommended action

## What Is Not Primary
- step count celebration
- calorie gamification
- badge or streak mechanics
- broad metric dashboards
- low-signal biometrics without decision impact
- detailed trend and export surfaces on the main screen

## Canonical Recommendation Rules

### Recovery Verdict Bands
- `80...100`: high readiness, push capacity available if recent load is not excessive
- `60...79`: solid readiness, normal training is appropriate
- `40...59`: mixed readiness, bias toward moderate work
- `0...39`: suppressed readiness, bias toward reduced intensity and earlier sleep

### Strain Day Types
- `light`: recovery is low, confidence is low, or recent load is elevated
- `moderate`: recovery is workable but not peak, or sleep debt exists
- `push`: recovery is high, confidence is high, and recent load is not already excessive

### Sleep Guidance Rules
- Start from baseline sleep need if available, otherwise use a conservative default
- Add sleep need when debt is present
- Add a small buffer when recovery is suppressed
- Only convert need into a precise bedtime when a wake-time anchor exists

## Implementation Contract
- Views should render assessment-oriented models, not raw HealthKit samples directly.
- View models should consume a shared daily assessment pipeline.
- Engines should expose:
  - inputs
  - confidence
  - explanation
  - recommendation impact
- If data quality is weak, the app should say so instead of projecting certainty.
