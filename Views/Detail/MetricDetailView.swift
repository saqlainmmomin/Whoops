import SwiftUI

// MARK: - Brutalist Metric Detail
// Deep data. Full transparency. No hiding.

struct MetricDetailView: View {
    let metricType: MetricType
    let dailyMetrics: DailyMetrics?
    let baseline: Baseline?
    let historicalMetrics: [DailyMetrics]

    init(metricType: MetricType, dailyMetrics: DailyMetrics?, baseline: Baseline?, historicalMetrics: [DailyMetrics] = []) {
        self.metricType = metricType
        self.dailyMetrics = dailyMetrics
        self.baseline = baseline
        self.historicalMetrics = historicalMetrics
    }

    var body: some View {
        ZStack {
            Theme.Colors.void.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Spacing.lg) {
                    switch metricType {
                    case .recovery:
                        recoveryDetailContent
                    case .strain:
                        strainDetailContent
                    case .sleep:
                        sleepDetailContent
                    case .heartRate:
                        heartRateDetailContent
                    case .hrv:
                        hrvDetailContent
                    case .activity:
                        activityDetailContent
                    }
                }
                .padding(Theme.Spacing.md)
            }
        }
        .navigationTitle(metricType.rawValue.uppercased())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.Colors.void, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Recovery Detail

    @ViewBuilder
    private var recoveryDetailContent: some View {
        if let recovery = dailyMetrics?.recoveryScore {
            // Score header
            VStack(spacing: Theme.Spacing.md) {
                Text("\(recovery.score)")
                    .font(Theme.Fonts.display(size: 72))
                    .foregroundColor(recovery.score <= 33 ? Theme.Colors.rust : Theme.Colors.bone)

                Text(recovery.category.rawValue.uppercased())
                    .font(Theme.Fonts.mono(size: 14))
                    .foregroundColor(Theme.Colors.chalk)
                    .tracking(2)

                Text(recovery.category.description)
                    .font(Theme.Fonts.label(size: 12))
                    .foregroundColor(Theme.Colors.chalk)
                    .multilineTextAlignment(.center)

                ConfidenceLabel(confidence: recovery.confidence)
            }
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(Theme.Colors.concrete)
            .brutalistBorder(recovery.score <= 33 ? Theme.Colors.rust : Theme.Colors.graphite)

            // Components
            InputBreakdown(
                title: "COMPONENTS",
                components: recovery.components
            )

            // Formula
            FormulaCard(
                title: "CALCULATION",
                formula: RecoveryDecomposition(recoveryScore: recovery, baseline: baseline).formula,
                timeWindow: RecoveryDecomposition(recoveryScore: recovery, baseline: baseline).timeWindow
            )

            // Raw inputs
            if let metrics = dailyMetrics {
                RawInputsCard(inputs: buildRecoveryInputs(from: metrics))
            }
        } else {
            MissingDataNotice(
                metricName: "RECOVERY",
                reason: "INSUFFICIENT DATA. REQUIRES SLEEP, HRV, AND HEART RATE."
            )
        }
    }

    // MARK: - Strain Detail

    @ViewBuilder
    private var strainDetailContent: some View {
        if let strain = dailyMetrics?.strainScore {
            VStack(spacing: Theme.Spacing.md) {
                Text("\(strain.score)")
                    .font(Theme.Fonts.display(size: 72))
                    .foregroundColor(strain.score >= 67 ? Theme.Colors.rust : Theme.Colors.bone)

                Text(strain.category.rawValue.uppercased())
                    .font(Theme.Fonts.mono(size: 14))
                    .foregroundColor(Theme.Colors.chalk)
                    .tracking(2)

                Text(strain.category.description)
                    .font(Theme.Fonts.label(size: 12))
                    .foregroundColor(Theme.Colors.chalk)
                    .multilineTextAlignment(.center)

                ConfidenceLabel(confidence: strain.confidence)
            }
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(Theme.Colors.concrete)
            .brutalistBorder(strain.score >= 67 ? Theme.Colors.rust : Theme.Colors.graphite)

            InputBreakdown(title: "COMPONENTS", components: strain.components)

            FormulaCard(
                title: "CALCULATION",
                formula: StrainDecomposition(strainScore: strain, baseline: baseline).formula,
                timeWindow: StrainDecomposition(strainScore: strain, baseline: baseline).timeWindow
            )

            if let zones = dailyMetrics?.zoneDistribution {
                ZoneDistributionCard(distribution: zones)
            }
        } else {
            MissingDataNotice(
                metricName: "STRAIN",
                reason: "NO ACTIVITY DATA. STRAIN CALCULATED FROM WORKOUTS AND HR ZONES."
            )
        }
    }

    // MARK: - Sleep Detail

    @ViewBuilder
    private var sleepDetailContent: some View {
        if let sleep = dailyMetrics?.sleep {
            VStack(spacing: Theme.Spacing.md) {
                // Duration header
                VStack(spacing: Theme.Spacing.xs) {
                    Text(formatHours(sleep.totalSleepHours))
                        .font(Theme.Fonts.display(size: 48))
                        .foregroundColor(Theme.Colors.bone)

                    if let baseline = baseline?.averageSleepDuration {
                        CompactBaselineComparison(
                            current: sleep.totalSleepHours,
                            baseline: baseline,
                            unit: "H",
                            higherIsBetter: true
                        )
                    }
                }
                .padding(Theme.Spacing.lg)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.concrete)
                .brutalistBorder()

                // Efficiency
                if sleep.averageEfficiency > 0 {
                    HStack {
                        Text("EFFICIENCY")
                            .font(Theme.Fonts.label(size: 10))
                            .foregroundColor(Theme.Colors.chalk)
                            .tracking(1)
                        Spacer()
                        Text("\(Int(sleep.averageEfficiency))%")
                            .font(Theme.Fonts.mono(size: 18))
                            .foregroundColor(Theme.Colors.bone)
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.steel)
                    .brutalistBorder()
                }

                SleepStageBreakdownCard(breakdown: sleep.combinedStageBreakdown)

                if let primary = sleep.primarySession {
                    SleepTimingCard(
                        bedtime: primary.startDate,
                        wakeTime: primary.endDate,
                        interruptions: primary.interruptionCount
                    )
                }
            }
        } else {
            MissingDataNotice(
                metricName: "SLEEP",
                reason: "NO SLEEP DATA. WEAR APPLE WATCH WHILE SLEEPING."
            )
        }
    }

    // MARK: - Heart Rate Detail

    @ViewBuilder
    private var heartRateDetailContent: some View {
        if let hr = dailyMetrics?.heartRate {
            VStack(spacing: Theme.Spacing.md) {
                if let resting = hr.restingBPM {
                    BaselineComparisonView(
                        current: resting,
                        baseline: baseline?.averageRestingHR ?? resting,
                        unit: "BPM",
                        label: "RESTING HR",
                        higherIsBetter: false
                    )
                }

                HStack(spacing: Theme.Spacing.sm) {
                    StatBox(label: "AVG", value: "\(hr.roundedAverage)", unit: "BPM")
                    StatBox(label: "MIN", value: "\(Int(hr.minBPM))", unit: "BPM")
                    StatBox(label: "MAX", value: "\(Int(hr.maxBPM))", unit: "BPM")
                }

                if let recovery = dailyMetrics?.hrRecovery {
                    HRRecoveryCard(recovery: recovery)
                }

                Text("\(hr.sampleCount) SAMPLES")
                    .font(Theme.Fonts.mono(size: 10))
                    .foregroundColor(Theme.Colors.ash)
                    .tracking(1)
            }
        } else {
            MissingDataNotice(
                metricName: "HEART RATE",
                reason: "NO HR DATA. ENSURE APPLE WATCH WORN PROPERLY."
            )
        }
    }

    // MARK: - HRV Detail

    @ViewBuilder
    private var hrvDetailContent: some View {
        if let hrv = dailyMetrics?.hrv {
            VStack(spacing: Theme.Spacing.md) {
                if let nightly = hrv.nightlySDNN {
                    BaselineComparisonView(
                        current: nightly,
                        baseline: baseline?.averageHRV ?? nightly,
                        unit: "MS",
                        label: "NIGHTLY HRV",
                        higherIsBetter: true
                    )
                }

                if let zScore = dailyMetrics?.hrvDeviation {
                    ZScoreDisplay(zScore: zScore, label: "DEVIATION FROM BASELINE")
                }

                HStack(spacing: Theme.Spacing.sm) {
                    StatBox(label: "AVG", value: "\(hrv.roundedAverage)", unit: "MS")
                    StatBox(label: "MIN", value: "\(Int(hrv.minSDNN))", unit: "MS")
                    StatBox(label: "MAX", value: "\(Int(hrv.maxSDNN))", unit: "MS")
                }

                Text("\(hrv.sampleCount) MEASUREMENTS")
                    .font(Theme.Fonts.mono(size: 10))
                    .foregroundColor(Theme.Colors.ash)
                    .tracking(1)
            }
        } else {
            MissingDataNotice(
                metricName: "HRV",
                reason: "NO HRV DATA. WEAR WATCH DURING SLEEP FOR ACCURATE READINGS."
            )
        }
    }

    // MARK: - Activity Detail

    @ViewBuilder
    private var activityDetailContent: some View {
        if let activity = dailyMetrics?.activity {
            VStack(spacing: Theme.Spacing.md) {
                BaselineComparisonView(
                    current: Double(activity.steps),
                    baseline: baseline?.averageSteps ?? Double(activity.steps),
                    unit: "STEPS",
                    label: "STEPS",
                    higherIsBetter: true
                )

                HStack(spacing: Theme.Spacing.sm) {
                    StatBox(label: "ACTIVE", value: "\(Int(activity.activeEnergy))", unit: "KCAL")
                    StatBox(label: "BASAL", value: "\(Int(activity.basalEnergy))", unit: "KCAL")
                    StatBox(label: "TOTAL", value: "\(Int(activity.totalEnergy))", unit: "KCAL")
                }

                HStack {
                    Text("DISTANCE")
                        .font(Theme.Fonts.label(size: 10))
                        .foregroundColor(Theme.Colors.chalk)
                        .tracking(1)
                    Spacer()
                    Text(activity.formattedDistance.uppercased())
                        .font(Theme.Fonts.mono(size: 14))
                        .foregroundColor(Theme.Colors.bone)
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.steel)
                .brutalistBorder()

                if let workouts = dailyMetrics?.workouts, workouts.totalWorkouts > 0 {
                    WorkoutSummaryCard(summary: workouts)
                }
            }
        } else {
            MissingDataNotice(
                metricName: "ACTIVITY",
                reason: "NO ACTIVITY DATA FOR TODAY."
            )
        }
    }

    // MARK: - Helpers

    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)H \(m)M"
    }

    private func buildRecoveryInputs(from metrics: DailyMetrics) -> [MetricInput] {
        var inputs: [MetricInput] = []

        if let hrv = metrics.hrv?.nightlySDNN ?? metrics.hrv?.averageSDNN {
            inputs.append(MetricInput(name: "HRV", value: hrv, unit: "ms", source: "Heart Rate Variability"))
        }

        if let rhr = metrics.heartRate?.restingBPM {
            inputs.append(MetricInput(name: "Resting HR", value: rhr, unit: "bpm", source: "Heart Rate"))
        }

        if let sleep = metrics.sleep?.totalSleepHours {
            inputs.append(MetricInput(name: "Sleep Duration", value: sleep, unit: "hours", source: "Sleep"))
        }

        if let interruptions = metrics.sleep?.totalInterruptions {
            inputs.append(MetricInput(name: "Interruptions", value: Double(interruptions), unit: "count", source: "Sleep"))
        }

        return inputs
    }
}

// MARK: - Supporting Views (Brutalist)

struct InputBreakdown: View {
    let title: String
    let components: [ScoreComponent]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title)
                .font(Theme.Fonts.label(size: 10))
                .foregroundColor(Theme.Colors.chalk)
                .tracking(2)

            ForEach(components) { component in
                HStack {
                    HStack(spacing: Theme.Spacing.sm) {
                        Rectangle()
                            .fill(weightColor(for: component.weight))
                            .frame(width: 3, height: 20)

                        Text(component.name.uppercased())
                            .font(Theme.Fonts.mono(size: 11))
                            .foregroundColor(Theme.Colors.chalk)
                    }

                    Spacer()

                    Text(component.formattedContribution)
                        .font(Theme.Fonts.mono(size: 12))
                        .foregroundColor(Theme.Colors.bone)
                }
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.steel)
                .brutalistBorder()
            }
        }
    }

    private func weightColor(for weight: Double) -> Color {
        switch weight {
        case 0.35...: return Theme.Colors.bone
        case 0.20..<0.35: return Theme.Colors.chalk
        default: return Theme.Colors.ash
        }
    }
}

struct FormulaCard: View {
    let title: String
    let formula: String
    let timeWindow: String

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    Text(title)
                        .font(Theme.Fonts.label(size: 10))
                        .foregroundColor(Theme.Colors.chalk)
                        .tracking(2)

                    Spacer()

                    Image(systemName: isExpanded ? "minus" : "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.Colors.chalk)
                }
            }

            if isExpanded {
                Text(formula)
                    .font(Theme.Fonts.mono(size: 10))
                    .foregroundColor(Theme.Colors.bone)
                    .padding(Theme.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Colors.steel)
                    .brutalistBorder()

                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(timeWindow.uppercased())
                        .font(Theme.Fonts.mono(size: 9))
                }
                .foregroundColor(Theme.Colors.ash)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.concrete)
        .brutalistBorder()
    }
}

struct RawInputsCard: View {
    let inputs: [MetricInput]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("RAW INPUTS")
                .font(Theme.Fonts.label(size: 10))
                .foregroundColor(Theme.Colors.chalk)
                .tracking(2)

            ForEach(inputs) { input in
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(input.name.uppercased())
                            .font(Theme.Fonts.mono(size: 10))
                            .foregroundColor(Theme.Colors.bone)
                        Text(input.source.uppercased())
                            .font(Theme.Fonts.label(size: 8))
                            .foregroundColor(Theme.Colors.ash)
                    }

                    Spacer()

                    Text(input.formattedValue.uppercased())
                        .font(Theme.Fonts.mono(size: 12))
                        .foregroundColor(Theme.Colors.bone)
                }
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.steel)
                .brutalistBorder()
            }
        }
    }
}

struct StatBox: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(label)
                .font(Theme.Fonts.label(size: 9))
                .foregroundColor(Theme.Colors.ash)
                .tracking(1)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(Theme.Fonts.mono(size: 20))
                    .foregroundColor(Theme.Colors.bone)

                Text(unit)
                    .font(Theme.Fonts.label(size: 9))
                    .foregroundColor(Theme.Colors.chalk)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.steel)
        .brutalistBorder()
    }
}

#Preview {
    NavigationStack {
        MetricDetailView(
            metricType: .recovery,
            dailyMetrics: nil,
            baseline: nil,
            historicalMetrics: []
        )
    }
}
