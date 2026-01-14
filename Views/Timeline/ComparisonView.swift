import SwiftUI

struct ComparisonView: View {
    let leftMetrics: DailyMetrics
    let rightMetrics: DailyMetrics
    let baseline: Baseline?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.sovereignBlack.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Date headers
                        dateHeaders

                        // Scores comparison
                        scoresSection

                        // Heart metrics
                        heartMetricsSection

                        // Sleep comparison
                        sleepSection

                        // Activity comparison
                        activitySection

                        // What changed analysis
                        changesAnalysisSection

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Compare Days")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.sovereignBlack, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.Colors.neonTeal)
                }
            }
        }
    }

    // MARK: - Date Headers

    private var dateHeaders: some View {
        HStack(spacing: 16) {
            dateHeader(for: leftMetrics.date)

            Image(systemName: "arrow.left.arrow.right")
                .foregroundColor(Theme.Colors.textGray)
                .font(.system(size: 14))

            dateHeader(for: rightMetrics.date)
        }
    }

    private func dateHeader(for date: Date) -> some View {
        VStack(spacing: 4) {
            Text(date.formatted(.dateTime.weekday(.wide)))
                .font(Theme.Fonts.label(size: 12))
                .foregroundColor(Theme.Colors.neonTeal)

            Text(date.formatted(.dateTime.month(.abbreviated).day()))
                .font(Theme.Fonts.header(size: 18))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.Colors.panelGray)
        .cornerRadius(8)
    }

    // MARK: - Scores Section

    private var scoresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("SCORES")

            HStack(spacing: 16) {
                // Recovery comparison
                VStack(spacing: 12) {
                    Text("Recovery")
                        .font(Theme.Fonts.label(size: 12))
                        .foregroundColor(Theme.Colors.textGray)

                    HStack(spacing: 20) {
                        scoreValue(leftMetrics.recoveryScore?.score, color: recoveryColor(leftMetrics.recoveryScore?.score))

                        changeBadge(
                            from: leftMetrics.recoveryScore?.score,
                            to: rightMetrics.recoveryScore?.score,
                            higherIsBetter: true
                        )

                        scoreValue(rightMetrics.recoveryScore?.score, color: recoveryColor(rightMetrics.recoveryScore?.score))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.Colors.panelGray)
                .cornerRadius(12)

                // Strain comparison
                VStack(spacing: 12) {
                    Text("Strain")
                        .font(Theme.Fonts.label(size: 12))
                        .foregroundColor(Theme.Colors.textGray)

                    HStack(spacing: 20) {
                        scoreValue(leftMetrics.strainScore?.score, color: strainColor(leftMetrics.strainScore?.score))

                        changeBadge(
                            from: leftMetrics.strainScore?.score,
                            to: rightMetrics.strainScore?.score,
                            higherIsBetter: false
                        )

                        scoreValue(rightMetrics.strainScore?.score, color: strainColor(rightMetrics.strainScore?.score))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.Colors.panelGray)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Heart Metrics Section

    private var heartMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("HEART METRICS")

            VStack(spacing: 8) {
                comparisonRow(
                    label: "HRV",
                    leftValue: leftMetrics.hrv?.nightlySDNN ?? leftMetrics.hrv?.averageSDNN,
                    rightValue: rightMetrics.hrv?.nightlySDNN ?? rightMetrics.hrv?.averageSDNN,
                    unit: "ms",
                    higherIsBetter: true,
                    color: Theme.Colors.neonTeal
                )

                Divider().background(Theme.Colors.textGray.opacity(0.3))

                comparisonRow(
                    label: "Resting HR",
                    leftValue: leftMetrics.heartRate?.restingBPM,
                    rightValue: rightMetrics.heartRate?.restingBPM,
                    unit: "bpm",
                    higherIsBetter: false,
                    color: Theme.Colors.neonRed
                )
            }
            .padding()
            .background(Theme.Colors.panelGray)
            .cornerRadius(12)
        }
    }

    // MARK: - Sleep Section

    private var sleepSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("SLEEP")

            VStack(spacing: 8) {
                comparisonRow(
                    label: "Duration",
                    leftValue: leftMetrics.sleep?.totalSleepHours,
                    rightValue: rightMetrics.sleep?.totalSleepHours,
                    unit: "hrs",
                    higherIsBetter: true,
                    color: Theme.Colors.neonGreen
                )

                Divider().background(Theme.Colors.textGray.opacity(0.3))

                comparisonRow(
                    label: "Efficiency",
                    leftValue: leftMetrics.sleep?.averageEfficiency,
                    rightValue: rightMetrics.sleep?.averageEfficiency,
                    unit: "%",
                    higherIsBetter: true,
                    color: Theme.Colors.neonGreen
                )

                if let leftDeep = leftMetrics.sleep?.combinedStageBreakdown.deepMinutes,
                   let rightDeep = rightMetrics.sleep?.combinedStageBreakdown.deepMinutes {
                    Divider().background(Theme.Colors.textGray.opacity(0.3))

                    comparisonRow(
                        label: "Deep Sleep",
                        leftValue: Double(leftDeep),
                        rightValue: Double(rightDeep),
                        unit: "min",
                        higherIsBetter: true,
                        color: .indigo
                    )
                }
            }
            .padding()
            .background(Theme.Colors.panelGray)
            .cornerRadius(12)
        }
    }

    // MARK: - Activity Section

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("ACTIVITY")

            VStack(spacing: 8) {
                if let leftSteps = leftMetrics.activity?.steps,
                   let rightSteps = rightMetrics.activity?.steps {
                    comparisonRow(
                        label: "Steps",
                        leftValue: Double(leftSteps),
                        rightValue: Double(rightSteps),
                        unit: "",
                        higherIsBetter: true,
                        color: Theme.Colors.neonGold
                    )

                    Divider().background(Theme.Colors.textGray.opacity(0.3))
                }

                comparisonRow(
                    label: "Active Energy",
                    leftValue: leftMetrics.activity?.activeEnergy,
                    rightValue: rightMetrics.activity?.activeEnergy,
                    unit: "kcal",
                    higherIsBetter: true,
                    color: Theme.Colors.neonGold
                )

                if let leftWorkout = leftMetrics.workouts?.totalDurationMinutes,
                   let rightWorkout = rightMetrics.workouts?.totalDurationMinutes {
                    Divider().background(Theme.Colors.textGray.opacity(0.3))

                    comparisonRow(
                        label: "Workout Time",
                        leftValue: Double(leftWorkout),
                        rightValue: Double(rightWorkout),
                        unit: "min",
                        higherIsBetter: true,
                        color: Theme.Colors.neonRed
                    )
                }
            }
            .padding()
            .background(Theme.Colors.panelGray)
            .cornerRadius(12)
        }
    }

    // MARK: - Changes Analysis

    private var changesAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("WHAT CHANGED")

            VStack(alignment: .leading, spacing: 8) {
                ForEach(significantChanges, id: \.self) { change in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: change.isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundColor(change.isPositive ? Theme.Colors.neonGreen : Theme.Colors.neonRed)
                            .font(.system(size: 14))

                        Text(change.description)
                            .font(Theme.Fonts.tensor(size: 14))
                            .foregroundColor(.white)
                    }
                }

                if significantChanges.isEmpty {
                    Text("No significant changes between these days")
                        .font(Theme.Fonts.tensor(size: 14))
                        .foregroundColor(Theme.Colors.textGray)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding()
            .background(Theme.Colors.panelGray)
            .cornerRadius(12)
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Theme.Fonts.label(size: 12))
            .foregroundColor(Theme.Colors.textGray)
            .tracking(1)
    }

    private func scoreValue(_ score: Int?, color: Color) -> some View {
        Text(score.map { "\($0)" } ?? "--")
            .font(Theme.Fonts.tensor(size: 24))
            .foregroundColor(color)
    }

    private func changeBadge(from: Int?, to: Int?, higherIsBetter: Bool) -> some View {
        Group {
            if let fromVal = from, let toVal = to {
                let change = toVal - fromVal
                let isPositive = higherIsBetter ? change > 0 : change < 0
                let percentage = fromVal > 0 ? abs(Double(change) / Double(fromVal) * 100) : 0

                if abs(change) >= 5 || percentage >= 10 {
                    HStack(spacing: 2) {
                        Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 10))
                        Text("\(abs(change))")
                            .font(Theme.Fonts.label(size: 10))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isPositive ? Theme.Colors.neonGreen.opacity(0.2) : Theme.Colors.neonRed.opacity(0.2))
                    .foregroundColor(isPositive ? Theme.Colors.neonGreen : Theme.Colors.neonRed)
                    .cornerRadius(4)
                } else {
                    Text("~")
                        .font(Theme.Fonts.label(size: 12))
                        .foregroundColor(Theme.Colors.textGray)
                }
            } else {
                Text("-")
                    .font(Theme.Fonts.label(size: 12))
                    .foregroundColor(Theme.Colors.textGray)
            }
        }
    }

    private func comparisonRow(label: String, leftValue: Double?, rightValue: Double?, unit: String, higherIsBetter: Bool, color: Color) -> some View {
        HStack {
            Text(label)
                .font(Theme.Fonts.tensor(size: 14))
                .foregroundColor(.white)

            Spacer()

            HStack(spacing: 16) {
                // Left value
                Text(formatValue(leftValue, unit: unit))
                    .font(Theme.Fonts.tensor(size: 14))
                    .foregroundColor(color)
                    .frame(width: 60, alignment: .trailing)

                // Change indicator
                if let left = leftValue, let right = rightValue {
                    let change = right - left
                    let percentage = left > 0 ? abs(change / left * 100) : 0

                    if percentage >= 10 {
                        Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor((higherIsBetter ? change > 0 : change < 0) ? Theme.Colors.neonGreen : Theme.Colors.neonRed)
                            .frame(width: 20)
                    } else {
                        Text("~")
                            .font(Theme.Fonts.label(size: 12))
                            .foregroundColor(Theme.Colors.textGray)
                            .frame(width: 20)
                    }
                } else {
                    Text("-")
                        .frame(width: 20)
                        .foregroundColor(Theme.Colors.textGray)
                }

                // Right value
                Text(formatValue(rightValue, unit: unit))
                    .font(Theme.Fonts.tensor(size: 14))
                    .foregroundColor(color)
                    .frame(width: 60, alignment: .leading)
            }
        }
    }

    private func formatValue(_ value: Double?, unit: String) -> String {
        guard let value = value else { return "--" }

        if unit == "hrs" {
            let h = Int(value)
            let m = Int((value - Double(h)) * 60)
            return "\(h)h\(m)m"
        } else if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        } else if value == floor(value) {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value)
        }
    }

    // MARK: - Color Helpers

    private func recoveryColor(_ score: Int?) -> Color {
        guard let score = score else { return Theme.Colors.textGray }
        switch score {
        case 0...33: return Theme.Colors.neonRed
        case 34...66: return Theme.Colors.neonGold
        default: return Theme.Colors.neonGreen
        }
    }

    private func strainColor(_ score: Int?) -> Color {
        guard let score = score else { return Theme.Colors.textGray }
        switch score {
        case 0...33: return .blue
        case 34...66: return Theme.Colors.neonGold
        default: return Theme.Colors.neonRed
        }
    }

    // MARK: - Significant Changes Analysis

    struct SignificantChange: Hashable {
        let description: String
        let isPositive: Bool
    }

    private var significantChanges: [SignificantChange] {
        var changes: [SignificantChange] = []

        // Recovery change
        if let leftRecovery = leftMetrics.recoveryScore?.score,
           let rightRecovery = rightMetrics.recoveryScore?.score {
            let change = rightRecovery - leftRecovery
            if abs(change) >= 10 {
                let direction = change > 0 ? "improved" : "decreased"
                changes.append(SignificantChange(
                    description: "Recovery \(direction) by \(abs(change)) points",
                    isPositive: change > 0
                ))
            }
        }

        // HRV change
        if let leftHRV = leftMetrics.hrv?.nightlySDNN ?? leftMetrics.hrv?.averageSDNN,
           let rightHRV = rightMetrics.hrv?.nightlySDNN ?? rightMetrics.hrv?.averageSDNN {
            let change = rightHRV - leftHRV
            let percentage = leftHRV > 0 ? abs(change / leftHRV * 100) : 0
            if percentage >= 15 {
                let direction = change > 0 ? "increased" : "decreased"
                changes.append(SignificantChange(
                    description: "HRV \(direction) by \(Int(percentage))%",
                    isPositive: change > 0
                ))
            }
        }

        // Sleep change
        if let leftSleep = leftMetrics.sleep?.totalSleepHours,
           let rightSleep = rightMetrics.sleep?.totalSleepHours {
            let change = rightSleep - leftSleep
            if abs(change) >= 1.0 {
                let direction = change > 0 ? "more" : "less"
                changes.append(SignificantChange(
                    description: String(format: "Slept %.1f hours \(direction)", abs(change)),
                    isPositive: change > 0
                ))
            }
        }

        // Activity change
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
