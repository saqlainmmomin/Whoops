import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = HabitsViewModel()
    @State private var selectedTab: HabitsTab = .patterns

    enum HabitsTab: String, CaseIterable {
        case patterns = "Patterns"
        case goals = "Goals"
        case reports = "Reports"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.sovereignBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Custom tab picker
                    HStack(spacing: 0) {
                        ForEach(HabitsTab.allCases, id: \.self) { tab in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = tab
                                }
                            } label: {
                                Text(tab.rawValue.uppercased())
                                    .font(Theme.Fonts.label(size: 12))
                                    .tracking(1)
                                    .foregroundColor(selectedTab == tab ? Theme.Colors.neonTeal : Theme.Colors.textGray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        selectedTab == tab ?
                                        Theme.Colors.neonTeal.opacity(0.1) :
                                        Color.clear
                                    )
                            }
                        }
                    }
                    .background(Theme.Colors.panelGray)

                    // Content
                    ScrollView(showsIndicators: false) {
                        switch selectedTab {
                        case .patterns:
                            patternsContent
                        case .goals:
                            goalsContent
                        case .reports:
                            reportsContent
                        }
                    }
                }
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Theme.Colors.sovereignBlack, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if selectedTab == .goals {
                        Button {
                            viewModel.showingGoalCreation = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Theme.Colors.neonTeal)
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingGoalCreation) {
                GoalCreationSheet(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadData(context: modelContext)
        }
    }

    // MARK: - Patterns Content

    private var patternsContent: some View {
        VStack(spacing: 16) {
            if viewModel.patterns.isEmpty {
                emptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "No Patterns Detected Yet",
                    subtitle: "Keep tracking for at least 7 days to discover patterns in your data"
                )
            } else {
                ForEach(viewModel.patterns, id: \.id) { pattern in
                    PatternCard(pattern: pattern) {
                        viewModel.dismissPattern(pattern, context: modelContext)
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Goals Content

    private var goalsContent: some View {
        VStack(spacing: 16) {
            if viewModel.goals.isEmpty {
                emptyStateView(
                    icon: "target",
                    title: "No Goals Set",
                    subtitle: "Set goals to track your progress and build habits"
                )

                // Suggested goals
                VStack(alignment: .leading, spacing: 12) {
                    Text("SUGGESTED GOALS")
                        .font(Theme.Fonts.label(size: 12))
                        .foregroundColor(Theme.Colors.textGray)
                        .tracking(1)

                    ForEach(viewModel.suggestedGoals, id: \.id) { goal in
                        SuggestedGoalRow(goal: goal) {
                            viewModel.addGoal(goal, context: modelContext)
                        }
                    }
                }
                .padding(.top, 20)
            } else {
                ForEach(viewModel.goals, id: \.id) { goal in
                    GoalCard(goal: goal) {
                        viewModel.deleteGoal(goal, context: modelContext)
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Reports Content

    private var reportsContent: some View {
        VStack(spacing: 16) {
            if viewModel.weeklyReports.isEmpty {
                emptyStateView(
                    icon: "doc.text",
                    title: "No Weekly Reports",
                    subtitle: "Reports are generated every Sunday with your weekly summary"
                )
            } else {
                ForEach(viewModel.weeklyReports, id: \.id) { report in
                    WeeklyReportCard(report: report)
                }
            }
        }
        .padding()
    }

    // MARK: - Empty State

    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(Theme.Colors.textGray)

            Text(title)
                .font(Theme.Fonts.header(size: 18))
                .foregroundColor(.white)

            Text(subtitle)
                .font(Theme.Fonts.tensor(size: 14))
                .foregroundColor(Theme.Colors.textGray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Pattern Card

struct PatternCard: View {
    let pattern: DetectedPattern
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: pattern.iconName)
                    .foregroundColor(accentColor)
                    .font(.system(size: 20))

                Text(pattern.patternType.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(Theme.Fonts.label(size: 12))
                    .foregroundColor(Theme.Colors.textGray)
                    .tracking(1)

                Spacer()

                // Confidence badge
                Text(pattern.confidence.uppercased())
                    .font(Theme.Fonts.label(size: 10))
                    .foregroundColor(confidenceColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(confidenceColor.opacity(0.2))
                    .cornerRadius(4)

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textGray)
                }
            }

            Text(pattern.descriptionText)
                .font(Theme.Fonts.tensor(size: 16))
                .foregroundColor(.white)

            // Impact
            HStack {
                Text("Impact:")
                    .font(Theme.Fonts.label(size: 12))
                    .foregroundColor(Theme.Colors.textGray)

                Text(pattern.impactDescription)
                    .font(Theme.Fonts.tensor(size: 14))
                    .foregroundColor(pattern.isPositive ? Theme.Colors.neonGreen : Theme.Colors.neonRed)
            }

            Divider()
                .background(Theme.Colors.panelGray)

            // Recommendation
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Theme.Colors.neonGold)
                    .font(.system(size: 14))

                Text(pattern.recommendation)
                    .font(Theme.Fonts.tensor(size: 14))
                    .foregroundColor(Theme.Colors.textGray)
            }

            Text("\(pattern.sampleSize) observations")
                .font(Theme.Fonts.label(size: 10))
                .foregroundColor(Theme.Colors.textGray.opacity(0.7))
        }
        .padding(16)
        .background(Theme.Colors.panelGray)
        .cornerRadius(12)
    }

    private var accentColor: Color {
        switch pattern.categoryColor {
        case "neonGreen": return Theme.Colors.neonGreen
        case "neonTeal": return Theme.Colors.neonTeal
        case "neonRed": return Theme.Colors.neonRed
        case "neonGold": return Theme.Colors.neonGold
        default: return Theme.Colors.textGray
        }
    }

    private var confidenceColor: Color {
        switch pattern.confidence {
        case "high": return Theme.Colors.neonGreen
        case "medium": return Theme.Colors.neonGold
        default: return Theme.Colors.textGray
        }
    }
}

// MARK: - Goal Card

struct GoalCard: View {
    let goal: Goal
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(goal.name)
                    .font(Theme.Fonts.tensor(size: 16))
                    .foregroundColor(.white)

                Spacer()

                if goal.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Text(goal.streakEmoji)
                        Text("\(goal.currentStreak)")
                            .font(Theme.Fonts.tensor(size: 14))
                            .foregroundColor(Theme.Colors.neonGold)
                    }
                }

                Menu {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete Goal", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(Theme.Colors.textGray)
                }
            }

            Text("Target: \(goal.targetDescription)")
                .font(Theme.Fonts.label(size: 12))
                .foregroundColor(Theme.Colors.textGray)

            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Current Streak")
                        .font(Theme.Fonts.label(size: 10))
                        .foregroundColor(Theme.Colors.textGray)
                    Text("\(goal.currentStreak) days")
                        .font(Theme.Fonts.tensor(size: 14))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading) {
                    Text("Longest Streak")
                        .font(Theme.Fonts.label(size: 10))
                        .foregroundColor(Theme.Colors.textGray)
                    Text("\(goal.longestStreak) days")
                        .font(Theme.Fonts.tensor(size: 14))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading) {
                    Text("Total Achieved")
                        .font(Theme.Fonts.label(size: 10))
                        .foregroundColor(Theme.Colors.textGray)
                    Text("\(goal.totalAchievements)")
                        .font(Theme.Fonts.tensor(size: 14))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(16)
        .background(Theme.Colors.panelGray)
        .cornerRadius(12)
    }
}

// MARK: - Suggested Goal Row

struct SuggestedGoalRow: View {
    let goal: Goal
    let onAdd: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.name)
                    .font(Theme.Fonts.tensor(size: 14))
                    .foregroundColor(.white)

                Text(goal.targetDescription)
                    .font(Theme.Fonts.label(size: 12))
                    .foregroundColor(Theme.Colors.textGray)
            }

            Spacer()

            Button {
                onAdd()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(Theme.Colors.neonTeal)
                    .font(.system(size: 24))
            }
        }
        .padding(12)
        .background(Theme.Colors.panelGray)
        .cornerRadius(8)
    }
}

// MARK: - Weekly Report Card

struct WeeklyReportCard: View {
    let report: WeeklyReport

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(report.weekRangeDescription)
                    .font(Theme.Fonts.header(size: 16))
                    .foregroundColor(.white)

                Spacer()

                Text("Grade: \(report.recoveryGrade)")
                    .font(Theme.Fonts.tensor(size: 14))
                    .foregroundColor(gradeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(gradeColor.opacity(0.2))
                    .cornerRadius(4)
            }

            // Stats grid
            HStack(spacing: 16) {
                statItem(label: "Avg Recovery", value: "\(Int(report.averageRecovery))%")
                statItem(label: "Avg HRV", value: "\(Int(report.averageHRV)) ms")
                statItem(label: "Sleep", value: String(format: "%.1fh", report.totalSleepHours / 7))
            }

            // Changes
            if report.recoveryChange != 0 {
                Text(report.changeDescription(for: report.recoveryChange, metric: "recovery"))
                    .font(Theme.Fonts.tensor(size: 12))
                    .foregroundColor(report.recoveryChange > 0 ? Theme.Colors.neonGreen : Theme.Colors.neonRed)
            }

            // Goal completion
            if report.goalsAttemptedCount > 0 {
                HStack {
                    Text("Goals:")
                        .font(Theme.Fonts.label(size: 12))
                        .foregroundColor(Theme.Colors.textGray)

                    Text("\(report.goalsAchievedCount)/\(report.goalsAttemptedCount) achieved")
                        .font(Theme.Fonts.tensor(size: 12))
                        .foregroundColor(.white)
                }
            }

            Text(report.overallAssessment)
                .font(Theme.Fonts.tensor(size: 14))
                .foregroundColor(Theme.Colors.textGray)
                .italic()
        }
        .padding(16)
        .background(Theme.Colors.panelGray)
        .cornerRadius(12)
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Theme.Fonts.label(size: 10))
                .foregroundColor(Theme.Colors.textGray)
            Text(value)
                .font(Theme.Fonts.tensor(size: 14))
                .foregroundColor(.white)
        }
    }

    private var gradeColor: Color {
        switch report.recoveryGrade {
        case "A": return Theme.Colors.neonGreen
        case "B": return Theme.Colors.neonTeal
        case "C": return Theme.Colors.neonGold
        default: return Theme.Colors.neonRed
        }
    }
}

// MARK: - Goal Creation Sheet

struct GoalCreationSheet: View {
    @ObservedObject var viewModel: HabitsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedMetric = "sleep"
    @State private var targetValue = ""
    @State private var comparison = ">="

    private let metrics = [
        ("sleep", "Sleep (hours)"),
        ("hrv", "HRV (ms)"),
        ("recovery", "Recovery (%)"),
        ("strain", "Strain"),
        ("steps", "Steps")
    ]

    private let comparisons = [">=", "<=", "range"]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.sovereignBlack.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Metric picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("METRIC")
                            .font(Theme.Fonts.label(size: 12))
                            .foregroundColor(Theme.Colors.textGray)
                            .tracking(1)

                        Picker("Metric", selection: $selectedMetric) {
                            ForEach(metrics, id: \.0) { metric in
                                Text(metric.1).tag(metric.0)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Target value
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TARGET VALUE")
                            .font(Theme.Fonts.label(size: 12))
                            .foregroundColor(Theme.Colors.textGray)
                            .tracking(1)

                        TextField("Enter target", text: $targetValue)
                            .keyboardType(.decimalPad)
                            .font(Theme.Fonts.tensor(size: 24))
                            .foregroundColor(.white)
                            .padding()
                            .background(Theme.Colors.panelGray)
                            .cornerRadius(8)
                    }

                    // Comparison
                    VStack(alignment: .leading, spacing: 8) {
                        Text("COMPARISON")
                            .font(Theme.Fonts.label(size: 12))
                            .foregroundColor(Theme.Colors.textGray)
                            .tracking(1)

                        Picker("Comparison", selection: $comparison) {
                            Text("At least (>=)").tag(">=")
                            Text("At most (<=)").tag("<=")
                        }
                        .pickerStyle(.segmented)
                    }

                    Spacer()

                    Button {
                        createGoal()
                    } label: {
                        Text("Create Goal")
                            .font(Theme.Fonts.header(size: 16))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.Colors.neonTeal)
                            .cornerRadius(12)
                    }
                    .disabled(targetValue.isEmpty)
                    .opacity(targetValue.isEmpty ? 0.5 : 1)
                }
                .padding()
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.sovereignBlack, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.neonTeal)
                }
            }
        }
    }

    private func createGoal() {
        guard let value = Double(targetValue) else { return }

        let unit: String
        let name: String

        switch selectedMetric {
        case "sleep":
            unit = "hrs"
            name = "Sleep \(comparison == ">=" ? "\(Int(value))+" : "under \(Int(value))") hours"
        case "hrv":
            unit = "ms"
            name = "HRV \(comparison == ">=" ? "above" : "below") \(Int(value))"
        case "recovery":
            unit = "%"
            name = "Recovery \(comparison == ">=" ? "\(Int(value))%+" : "under \(Int(value))%")"
        case "strain":
            unit = ""
            name = "Strain \(comparison == ">=" ? "above" : "below") \(Int(value))"
        case "steps":
            unit = "steps"
            name = "\(Int(value/1000))K+ steps"
        default:
            unit = ""
            name = "Custom goal"
        }

        let goal = Goal(
            metricType: selectedMetric,
            targetValue: value,
            comparison: comparison,
            unit: unit,
            name: name
        )

        viewModel.addGoal(goal, context: modelContext)
        dismiss()
    }
}

#Preview {
    HabitsView()
}
