import SwiftUI

// MARK: - Brutalist Comparison View
// Side-by-side. Hard data. No ambiguity.

struct ComparisonView: View {
    let leftMetrics: DailyMetrics
    let rightMetrics: DailyMetrics
    let baseline: Baseline?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.void.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Date headers
                        dateHeaders
                            .padding(.bottom, Theme.Spacing.lg)

                        // Scores comparison
                        scoresSection
                        divider

                        // Heart metrics
                        heartMetricsSection
                        divider

                        // Sleep comparison
                        sleepSection
                        divider

                        // Activity comparison
                        activitySection
                        divider

                        // Changes analysis
                        changesAnalysisSection

                        Spacer(minLength: 40)
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .navigationTitle("COMPARE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.void, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("DONE") { dismiss() }
                        .font(Theme.Fonts.mono(size: 12))
                        .foregroundColor(Theme.Colors.bone)
                }
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.Colors.graphite)
            .frame(height: 1)
            .padding(.vertical, Theme.Spacing.md)
    }

    // MARK: - Date Headers

    private var dateHeaders: some View {
        HStack(spacing: Theme.Spacing.md) {
            dateHeader(for: leftMetrics.date)

            Text("VS")
                .font(Theme.Fonts.mono(size: 14))
                .foregroundColor(Theme.Colors.chalk)

            dateHeader(for: rightMetrics.date)
        }
    }

    private func dateHeader(for date: Date) -> some View {
        VStack(spacing: 2) {
            Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                .font(Theme.Fonts.label(size: 10))
                .foregroundColor(Theme.Colors.chalk)
                .tracking(1)

            Text(date.formatted(.dateTime.month(.abbreviated).day()).uppercased())
                .font(Theme.Fonts.mono(size: 16))
                .foregroundColor(Theme.Colors.bone)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
        .background(Theme.Colors.concrete)
        .brutalistBorder()
    }

    // MARK: - Scores Section

    private var scoresSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("SCORES")

            HStack(spacing: Theme.Spacing.sm) {
                // Recovery
                VStack(spacing: Theme.Spacing.sm) {
                    Text("RECOVERY")
                        .font(Theme.Fonts.label(size: 9))
                        .foregroundColor(Theme.Colors.chalk)
                        .tracking(1)

                    HStack(spacing: Theme.Spacing.md) {
                        scoreValue(leftMetrics.recoveryScore?.score, isCritical: (leftMetrics.recoveryScore?.score ?? 100) <= 33)
                        changeIndicator(from: leftMetrics.recoveryScore?.score, to: rightMetrics.recoveryScore?.score, higherIsBetter: true)
                        scoreValue(rightMetrics.recoveryScore?.score, isCritical: (rightMetrics.recoveryScore?.score ?? 100) <= 33)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.concrete)
                .brutalistBorder()

                // Strain
                VStack(spacing: Theme.Spacing.sm) {
                    Text("STRAIN")
                        .font(Theme.Fonts.label(size: 9))
                        .foregroundColor(Theme.Colors.chalk)
                        .tracking(1)

                    HStack(spacing: Theme.Spacing.md) {
                        scoreValue(leftMetrics.strainScore?.score, isCritical: (leftMetrics.strainScore?.score ?? 0) >= 67)
                        changeIndicator(from: leftMetrics.strainScore?.score, to: rightMetrics.strainScore?.score, higherIsBetter: false)
                        scoreValue(rightMetrics.strainScore?.score, isCritical: (rightMetrics.strainScore?.score ?? 0) >= 67)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.concrete)
                .brutalistBorder()
            }
        }
    }

    // MARK: - Heart Metrics Section

    private var heartMetricsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("HEART")

            VStack(spacing: Theme.Spacing.xs) {
                comparisonRow(
                    label: "HRV",
                    leftValue: leftMetrics.hrv?.nightlySDNN ?? leftMetrics.hrv?.averageSDNN,
                    rightValue: rightMetrics.hrv?.nightlySDNN ?? rightMetrics.hrv?.averageSDNN,
                    unit: "MS",
                    higherIsBetter: true
                )

                Rectangle().fill(Theme.Colors.graphite).frame(height: 1)

                comparisonRow(
                    label: "RHR",
                    leftValue: leftMetrics.heartRate?.restingBPM,
                    rightValue: rightMetrics.heartRate?.restingBPM,
                    unit: "BPM",
                    higherIsBetter: false
                )
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.concrete)
            .brutalistBorder()
        }
    }

    // MARK: - Sleep Section

    private var sleepSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("SLEEP")

            VStack(spacing: Theme.Spacing.xs) {
                comparisonRow(
                    label: "DURATION",
                    leftValue: leftMetrics.sleep?.totalSleepHours,
                    rightValue: rightMetrics.sleep?.totalSleepHours,
                    unit: "HRS",
                    higherIsBetter: true
                )

                Rectangle().fill(Theme.Colors.graphite).frame(height: 1)

                comparisonRow(
                    label: "EFFICIENCY",
                    leftValue: leftMetrics.sleep?.averageEfficiency,
                    rightValue: rightMetrics.sleep?.averageEfficiency,
                    unit: "%",
                    higherIsBetter: true
                )

                if let leftDeep = leftMetrics.sleep?.combinedStageBreakdown.deepMinutes,
                   let rightDeep = rightMetrics.sleep?.combinedStageBreakdown.deepMinutes {
                    Rectangle().fill(Theme.Colors.graphite).frame(height: 1)

                    comparisonRow(
                        label: "DEEP",
                        leftValue: Double(leftDeep),
                        rightValue: Double(rightDeep),
                        unit: "MIN",
                        higherIsBetter: true
                    )
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.concrete)
            .brutalistBorder()
        }
    }

    // MARK: - Activity Section

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("ACTIVITY")

            VStack(spacing: Theme.Spacing.xs) {
                if let leftSteps = leftMetrics.activity?.steps,
                   let rightSteps = rightMetrics.activity?.steps {
                    comparisonRow(
                        label: "STEPS",
                        leftValue: Double(leftSteps),
                        rightValue: Double(rightSteps),
                        unit: "",
                        higherIsBetter: true
                    )

                    Rectangle().fill(Theme.Colors.graphite).frame(height: 1)
                }

                comparisonRow(
                    label: "ACTIVE",
                    leftValue: leftMetrics.activity?.activeEnergy,
                    rightValue: rightMetrics.activity?.activeEnergy,
                    unit: "KCAL",
                    higherIsBetter: true
                )

                if let leftWorkout = leftMetrics.workouts?.totalDurationMinutes,
                   let rightWorkout = rightMetrics.workouts?.totalDurationMinutes {
                    Rectangle().fill(Theme.Colors.graphite).frame(height: 1)

                    comparisonRow(
                        label: "WORKOUT",
                        leftValue: Double(leftWorkout),
                        rightValue: Double(rightWorkout),
                        unit: "MIN",
                        higherIsBetter: true
                    )
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.concrete)
            .brutalistBorder()
        }
    }

    // MARK: - Changes Analysis

    private var changesAnalysisSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("CHANGES")

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ForEach(significantChanges, id: \.self) { change in
                    HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                        Image(systemName: change.isPositive ? "arrow.up" : "arrow.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(change.isPositive ? Theme.Colors.bone : Theme.Colors.rust)

                        Text(change.description.uppercased())
                            .font(Theme.Fonts.mono(size: 11))
                            .foregroundColor(Theme.Colors.bone)
                    }
                }

                if significantChanges.isEmpty {
                    Text("NO SIGNIFICANT CHANGES")
                        .font(Theme.Fonts.mono(size: 11))
                        .foregroundColor(Theme.Colors.chalk)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.concrete)
            .brutalistBorder()
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Theme.Fonts.label(size: 10))
            .foregroundColor(Theme.Colors.chalk)
            .tracking(2)
    }

    private func scoreValue(_ score: Int?, isCritical: Bool) -> some View {
        Text(score.map { "\($0)" } ?? "--")
            .font(Theme.Fonts.display(size: 24))
            .foregroundColor(score == nil ? Theme.Colors.ash : (isCritical ? Theme.Colors.rust : Theme.Colors.bone))
            .monospacedDigit()
    }

    private func changeIndicator(from: Int?, to: Int?, higherIsBetter: Bool) -> some View {
        Group {
            if let fromVal = from, let toVal = to {
                let change = toVal - fromVal
                let isPositive = higherIsBetter ? change > 0 : change < 0

                if abs(change) >= 5 {
                    HStack(spacing: 2) {
                        Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 9, weight: .bold))
                        Text("\(abs(change))")
                            .font(Theme.Fonts.mono(size: 9))
                    }
                    .foregroundColor(isPositive ? Theme.Colors.bone : Theme.Colors.rust)
                } else {
                    Text("~")
                        .font(Theme.Fonts.mono(size: 12))
                        .foregroundColor(Theme.Colors.ash)
                }
            } else {
                Text("-")
                    .font(Theme.Fonts.mono(size: 12))
                    .foregroundColor(Theme.Colors.ash)
            }
        }
    }

    private func comparisonRow(label: String, leftValue: Double?, rightValue: Double?, unit: String, higherIsBetter: Bool) -> some View {
        HStack {
            Text(label)
                .font(Theme.Fonts.mono(size: 11))
                .foregroundColor(Theme.Colors.chalk)

            Spacer()

            HStack(spacing: Theme.Spacing.md) {
                Text(formatValue(leftValue, unit: unit))
                    .font(Theme.Fonts.mono(size: 12))
                    .foregroundColor(Theme.Colors.bone)
                    .frame(width: 55, alignment: .trailing)

                // Change indicator
                if let left = leftValue, let right = rightValue {
                    let change = right - left
                    let percentage = left > 0 ? abs(change / left * 100) : 0

                    if percentage >= 10 {
                        Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor((higherIsBetter ? change > 0 : change < 0) ? Theme.Colors.bone : Theme.Colors.rust)
                            .frame(width: 16)
                    } else {
                        Text("~")
                            .font(Theme.Fonts.mono(size: 10))
                            .foregroundColor(Theme.Colors.ash)
                            .frame(width: 16)
                    }
                } else {
                    Text("-")
                        .frame(width: 16)
                        .foregroundColor(Theme.Colors.ash)
                }

                Text(formatValue(rightValue, unit: unit))
                    .font(Theme.Fonts.mono(size: 12))
                    .foregroundColor(Theme.Colors.bone)
                    .frame(width: 55, alignment: .leading)
            }
        }
    }

    private func formatValue(_ value: Double?, unit: String) -> String {
        guard let value = value else { return "--" }

        if unit == "HRS" {
            let h = Int(value)
            let m = Int((value - Double(h)) * 60)
            return "\(h)H\(m)M"
        } else if value >= 1000 {
            return String(format: "%.1fK", value / 1000)
        } else if value == floor(value) {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value)
        }
    }

    // MARK: - Significant Changes Analysis

    struct SignificantChange: Hashable {
        let description: String
        let isPositive: Bool
    }

    private var significantChanges: [SignificantChange] {
        var changes: [SignificantChange] = []

        if let leftRecovery = leftMetrics.recoveryScore?.score,
           let rightRecovery = rightMetrics.recoveryScore?.score {
            let change = rightRecovery - leftRecovery
            if abs(change) >= 10 {
                let direction = change > 0 ? "improved" : "decreased"
                changes.append(SignificantChange(
                    description: "Recovery \(direction) by \(abs(change)) pts",
                    isPositive: change > 0
                ))
            }
        }

        if let leftHRV = leftMetrics.hrv?.nightlySDNN ?? leftMetrics.hrv?.averageSDNN,
           let rightHRV = rightMetrics.hrv?.nightlySDNN ?? rightMetrics.hrv?.averageSDNN {
            let change = rightHRV - leftHRV
            let percentage = leftHRV > 0 ? abs(change / leftHRV * 100) : 0
            if percentage >= 15 {
                let direction = change > 0 ? "up" : "down"
                changes.append(SignificantChange(
                    description: "HRV \(direction) \(Int(percentage))%",
                    isPositive: change > 0
                ))
            }
        }

        if let leftSleep = leftMetrics.sleep?.totalSleepHours,
           let rightSleep = rightMetrics.sleep?.totalSleepHours {
            let change = rightSleep - leftSleep
            if abs(change) >= 1.0 {
                let direction = change > 0 ? "more" : "less"
                changes.append(SignificantChange(
                    description: String(format: "%.1fh \(direction) sleep", abs(change)),
                    isPositive: change > 0
                ))
            }
        }

        if let leftEnergy = leftMetrics.activity?.activeEnergy,
           let rightEnergy = rightMetrics.activity?.activeEnergy,
           leftEnergy > 0 {
            let change = rightEnergy - leftEnergy
            let percentage = abs(change / leftEnergy * 100)
            if percentage >= 30 {
                let direction = change > 0 ? "higher" : "lower"
                changes.append(SignificantChange(
                    description: "Activity \(Int(percentage))% \(direction)",
                    isPositive: change > 0
                ))
            }
        }

        return changes
    }
}

#Preview {
    ComparisonView(
        leftMetrics: DailyMetrics.placeholder(for: Date()),
        rightMetrics: DailyMetrics.placeholder(for: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
        baseline: nil
    )
}
