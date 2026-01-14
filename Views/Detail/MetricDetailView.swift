import SwiftUI

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
            Theme.Colors.sovereignBlack.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
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
                .padding()
            }
        }
        .navigationTitle(metricType.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.Colors.sovereignBlack, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Recovery Detail

    @ViewBuilder
    private var recoveryDetailContent: some View {
        if let recovery = dailyMetrics?.recoveryScore {
            // Score header
            VStack(spacing: 8) {
                MetricGauge(
                    value: Double(recovery.score),
                    maxValue: 100,
                    color: recoveryColor(recovery.score),
                    size: 120
                )

                Text(recovery.category.rawValue)
                    .font(.headline)

                Text(recovery.category.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                ConfidenceLabel(confidence: recovery.confidence)
            }
            .padding()

            // Component breakdown
            InputBreakdown(
                title: "Score Components",
                components: recovery.components
            )

            // Formula transparency
            FormulaCard(
                title: "How Recovery is Calculated",
                formula: RecoveryDecomposition(recoveryScore: recovery, baseline: baseline).formula,
                timeWindow: RecoveryDecomposition(recoveryScore: recovery, baseline: baseline).timeWindow
            )

            // Raw inputs
            if let metrics = dailyMetrics {
                RawInputsCard(
                    inputs: buildRecoveryInputs(from: metrics)
                )
            }
        } else {
            MissingDataNotice(
                metricName: "Recovery Score",
                reason: "Insufficient data to calculate recovery. Ensure you have sleep, HRV, and heart rate data."
            )
        }
    }

    // MARK: - Strain Detail

    @ViewBuilder
    private var strainDetailContent: some View {
        if let strain = dailyMetrics?.strainScore {
            VStack(spacing: 8) {
                MetricGauge(
                    value: Double(strain.score),
                    maxValue: 100,
                    color: strainColor(strain.score),
                    size: 120
                )

                Text(strain.category.rawValue)
                    .font(.headline)

                Text(strain.category.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                ConfidenceLabel(confidence: strain.confidence)
            }
            .padding()

            InputBreakdown(
                title: "Score Components",
                components: strain.components
            )

            FormulaCard(
                title: "How Strain is Calculated",
                formula: StrainDecomposition(strainScore: strain, baseline: baseline).formula,
                timeWindow: StrainDecomposition(strainScore: strain, baseline: baseline).timeWindow
            )

            if let zones = dailyMetrics?.zoneDistribution {
                ZoneDistributionCard(distribution: zones)
            }
        } else {
            MissingDataNotice(
                metricName: "Strain Score",
                reason: "No activity data recorded today. Strain is calculated from workouts and heart rate zones."
            )
        }
    }

    // MARK: - Sleep Detail

    @ViewBuilder
    private var sleepDetailContent: some View {
        if let sleep = dailyMetrics?.sleep {
            VStack(spacing: 16) {
                // Duration header
                VStack(spacing: 4) {
                    Text(formatHours(sleep.totalSleepHours))
                        .font(.system(size: 48, weight: .bold, design: .rounded))

                    if let baseline = baseline?.averageSleepDuration {
                        CompactBaselineComparison(
                            current: sleep.totalSleepHours,
                            baseline: baseline,
                            unit: "h",
                            higherIsBetter: true
                        )
                    }
                }

                // Efficiency
                if sleep.averageEfficiency > 0 {
                    HStack {
                        Text("Sleep Efficiency")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(sleep.averageEfficiency))%")
                            .font(.headline)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // Stage breakdown
                SleepStageBreakdownCard(breakdown: sleep.combinedStageBreakdown)

                // Timing
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
                metricName: "Sleep",
                reason: "No sleep data recorded. Wear your Apple Watch while sleeping."
            )
        }
    }

    // MARK: - Heart Rate Detail

    @ViewBuilder
    private var heartRateDetailContent: some View {
        if let hr = dailyMetrics?.heartRate {
            VStack(spacing: 16) {
                // Resting HR
                if let resting = hr.restingBPM {
                    BaselineComparisonView(
                        current: resting,
                        baseline: baseline?.averageRestingHR ?? resting,
                        unit: "bpm",
                        label: "Resting Heart Rate",
                        higherIsBetter: false
                    )
                }

                // Daily stats
                HStack(spacing: 16) {
                    StatBox(label: "Average", value: "\(hr.roundedAverage)", unit: "bpm")
                    StatBox(label: "Min", value: "\(Int(hr.minBPM))", unit: "bpm")
                    StatBox(label: "Max", value: "\(Int(hr.maxBPM))", unit: "bpm")
                }

                // HR Recovery if available
                if let recovery = dailyMetrics?.hrRecovery {
                    HRRecoveryCard(recovery: recovery)
                }

                Text("\(hr.sampleCount) heart rate samples recorded today")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } else {
            MissingDataNotice(
                metricName: "Heart Rate",
                reason: "No heart rate data available. Ensure your Apple Watch is worn properly."
            )
        }
    }

    // MARK: - HRV Detail

    @ViewBuilder
    private var hrvDetailContent: some View {
        if let hrv = dailyMetrics?.hrv {
            VStack(spacing: 16) {
                // Nightly HRV
                if let nightly = hrv.nightlySDNN {
                    BaselineComparisonView(
                        current: nightly,
                        baseline: baseline?.averageHRV ?? nightly,
                        unit: "ms",
                        label: "Nightly HRV (SDNN)",
                        higherIsBetter: true
                    )
                }

                // Z-score if available
                if let zScore = dailyMetrics?.hrvDeviation {
                    ZScoreDisplay(zScore: zScore, label: "HRV Deviation from Baseline")
                }

                // Stats
                HStack(spacing: 16) {
                    StatBox(label: "Average", value: "\(hrv.roundedAverage)", unit: "ms")
                    StatBox(label: "Min", value: "\(Int(hrv.minSDNN))", unit: "ms")
                    StatBox(label: "Max", value: "\(Int(hrv.maxSDNN))", unit: "ms")
                }

                Text("\(hrv.sampleCount) HRV measurements recorded")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Educational note
                VStack(alignment: .leading, spacing: 8) {
                    Text("About HRV")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Heart Rate Variability measures the variation in time between heartbeats. Higher HRV typically indicates better recovery and cardiovascular fitness. HRV is most accurate when measured during sleep.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        } else {
            MissingDataNotice(
                metricName: "HRV",
                reason: "No HRV data available. Wear your Apple Watch during sleep for accurate HRV measurements."
            )
        }
    }

    // MARK: - Activity Detail

    @ViewBuilder
    private var activityDetailContent: some View {
        if let activity = dailyMetrics?.activity {
            VStack(spacing: 16) {
                // Steps
                BaselineComparisonView(
                    current: Double(activity.steps),
                    baseline: baseline?.averageSteps ?? Double(activity.steps),
                    unit: "steps",
                    label: "Steps",
                    higherIsBetter: true
                )

                // Energy
                HStack(spacing: 16) {
                    StatBox(label: "Active", value: "\(Int(activity.activeEnergy))", unit: "kcal")
                    StatBox(label: "Basal", value: "\(Int(activity.basalEnergy))", unit: "kcal")
                    StatBox(label: "Total", value: "\(Int(activity.totalEnergy))", unit: "kcal")
                }

                // Distance
                HStack {
                    Text("Distance")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(activity.formattedDistance)
                        .fontWeight(.medium)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Workouts
                if let workouts = dailyMetrics?.workouts, workouts.totalWorkouts > 0 {
                    WorkoutSummaryCard(summary: workouts)
                }
            }
        } else {
            MissingDataNotice(
                metricName: "Activity",
                reason: "No activity data available for today."
            )
        }
    }

    // MARK: - Helpers

    private func recoveryColor(_ score: Int) -> Color {
        switch score {
        case 0...33: return .red
        case 34...66: return .yellow
        default: return .green
        }
    }

    private func strainColor(_ score: Int) -> Color {
        switch score {
        case 0...33: return .blue
        case 34...66: return .orange
        default: return .red
        }
    }

    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h \(m)m"
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

// MARK: - Supporting Views

struct InputBreakdown: View {
    let title: String
    let components: [ScoreComponent]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            ForEach(components) { component in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(component.name)
                            .font(.subheadline)

                        Text("Weight: \(Int(component.weight * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(component.formattedContribution)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("Raw: \(component.formattedRawValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}

struct FormulaCard: View {
    let title: String
    let formula: String
    let timeWindow: String

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }

            if isExpanded {
                Text(formula)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(8)

                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text(timeWindow)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RawInputsCard: View {
    let inputs: [MetricInput]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Raw Input Values")
                .font(.headline)

            ForEach(inputs) { input in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(input.name)
                            .font(.subheadline)
                        Text(input.source)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(input.formattedValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatBox: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
