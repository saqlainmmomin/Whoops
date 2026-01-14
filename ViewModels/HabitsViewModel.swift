import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class HabitsViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var patterns: [DetectedPattern] = []
    @Published var weeklyReports: [WeeklyReport] = []
    @Published var isLoading = false
    @Published var showingGoalCreation = false

    private let patternDetector = PatternDetector()

    func loadData(context: ModelContext) async {
        isLoading = true

        // Load goals
        let goalDescriptor = FetchDescriptor<Goal>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        goals = (try? context.fetch(goalDescriptor)) ?? []

        // Load patterns
        let patternDescriptor = FetchDescriptor<DetectedPattern>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.detectedDate, order: .reverse)]
        )
        patterns = (try? context.fetch(patternDescriptor)) ?? []

        // Load recent weekly reports
        let reportDescriptor = FetchDescriptor<WeeklyReport>(
            sortBy: [SortDescriptor(\.weekStartDate, order: .reverse)]
        )
        weeklyReports = (try? context.fetch(reportDescriptor))?.prefix(4).map { $0 } ?? []

        isLoading = false
    }

    func analyzePatterns(metrics: [DailyMetrics], context: ModelContext) async {
        isLoading = true
        patterns = await patternDetector.detectPatterns(from: metrics, context: context)
        isLoading = false
    }

    func addGoal(_ goal: Goal, context: ModelContext) {
        context.insert(goal)
        try? context.save()
        goals.insert(goal, at: 0)
    }

    func deleteGoal(_ goal: Goal, context: ModelContext) {
        goal.isActive = false
        try? context.save()
        goals.removeAll { $0.id == goal.id }
    }

    func dismissPattern(_ pattern: DetectedPattern, context: ModelContext) {
        pattern.isActive = false
        try? context.save()
        patterns.removeAll { $0.id == pattern.id }
    }

    func updateGoalProgress(for metrics: DailyMetrics, context: ModelContext) {
        for goal in goals {
            let value = extractValue(for: goal.metricType, from: metrics)
            guard let value = value else { continue }

            if goal.isAchieved(with: value) {
                goal.recordAchievement(on: metrics.date)
            } else {
                goal.recordMiss(on: metrics.date)
            }
        }
        try? context.save()
    }

    private func extractValue(for metricType: String, from metrics: DailyMetrics) -> Double? {
        switch metricType {
        case "sleep":
            return metrics.sleep?.totalSleepHours
        case "hrv":
            return metrics.hrv?.nightlySDNN ?? metrics.hrv?.averageSDNN
        case "recovery":
            return metrics.recoveryScore.map { Double($0.score) }
        case "strain":
            return metrics.strainScore.map { Double($0.score) }
        case "rhr":
            return metrics.heartRate?.restingBPM
        case "steps":
            return metrics.activity.map { Double($0.steps) }
        default:
            return nil
        }
    }

    // Preset goals
    var suggestedGoals: [Goal] {
        [
            Goal.sleepGoal(hours: 7),
            Goal.hrvGoal(target: 40),
            Goal.recoveryGoal(target: 60),
            Goal.strainBalanceGoal(min: 40, max: 60),
            Goal.stepsGoal(target: 10000)
        ]
    }
}
