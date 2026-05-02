import Foundation
import SwiftUI
import SwiftData
import Combine

enum TimelineRange: String, CaseIterable {
    case week = "7 Days"
    case month = "28 Days"
    case quarter = "90 Days"

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 28
        case .quarter: return 90
        }
    }
}

@MainActor
class TimelineViewModel: ObservableObject {
    @Published var dailyMetrics: [DailyMetrics] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var timeRange: TimelineRange = .month {
        didSet {
            if let manager = lastHealthKitManager, let context = lastModelContext {
                Task {
                    await loadData(healthKitManager: manager, modelContext: context)
                }
            }
        }
    }

    @Published var baseline: Baseline?

    private var lastHealthKitManager: HealthKitManager?
    private var lastModelContext: ModelContext?
    private var assessmentPipeline: DailyAssessmentPipeline?

    // MARK: - Data Loading

    func loadData(healthKitManager: HealthKitManager, modelContext: ModelContext) async {
        guard !isLoading else { return }
        lastHealthKitManager = healthKitManager
        lastModelContext = modelContext
        assessmentPipeline = DailyAssessmentPipeline(healthKitManager: healthKitManager)

        isLoading = true
        errorMessage = nil

        do {
            guard let assessmentPipeline else {
                throw DailyAssessmentPipelineError.assessmentUnavailable(Date())
            }

            let result = try await assessmentPipeline.loadHistory(
                days: timeRange.days,
                endingOn: Date(),
                context: modelContext
            )

            dailyMetrics = result.dailyMetrics.sorted { $0.date > $1.date }
            baseline = result.latestAssessment?.sevenDayBaseline
        } catch {
            errorMessage = "Failed to load timeline: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Week Summary

    struct WeekSummary {
        let averageRecovery: Int?
        let averageStrain: Int?
        let totalSleepHours: Double
        let totalWorkoutMinutes: Int
    }

    func weekSummary(for weekStart: Date) -> WeekSummary? {
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart)!
        let weekMetrics = dailyMetrics.filter { $0.date >= weekStart && $0.date < weekEnd }

        guard !weekMetrics.isEmpty else { return nil }

        let recoveryScores = weekMetrics.compactMap { $0.recoveryScore?.score }
        let strainScores = weekMetrics.compactMap { $0.strainScore?.score }
        let sleepHours = weekMetrics.compactMap { $0.sleep?.totalSleepHours }
        let workoutMinutes = weekMetrics.compactMap { $0.workouts?.totalDurationMinutes }

        return WeekSummary(
            averageRecovery: recoveryScores.isEmpty ? nil : recoveryScores.reduce(0, +) / recoveryScores.count,
            averageStrain: strainScores.isEmpty ? nil : strainScores.reduce(0, +) / strainScores.count,
            totalSleepHours: sleepHours.reduce(0, +),
            totalWorkoutMinutes: workoutMinutes.reduce(0, +)
        )
    }
}
