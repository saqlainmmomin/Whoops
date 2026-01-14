import Foundation
import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var lastSyncDate: Date?

    // Current day metrics (computed from HealthKit data)
    @Published var todayMetrics: DailyMetrics?
    @Published var weeklyMetrics: [DailyMetrics] = []

    // Baselines
    @Published var sevenDayBaseline: Baseline?
    @Published var twentyEightDayBaseline: Baseline?

    // Navigation state
    @Published var selectedTab: Tab = .dashboard
    @Published var showingMetricDetail: MetricType?

    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case timeline = "Timeline"
        case export = "Export"

        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2"
            case .timeline: return "calendar"
            case .export: return "square.and.arrow.up"
            }
        }
    }

    func setError(_ message: String) {
        errorMessage = message
        // Auto-dismiss after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            if self?.errorMessage == message {
                self?.errorMessage = nil
            }
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func updateSyncDate() {
        lastSyncDate = Date()
    }
}

enum MetricType: String, CaseIterable, Identifiable {
    case recovery = "Recovery"
    case strain = "Strain"
    case sleep = "Sleep"
    case heartRate = "Heart Rate"
    case hrv = "HRV"
    case activity = "Activity"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .recovery: return "arrow.up.heart.fill"
        case .strain: return "flame.fill"
        case .sleep: return "bed.double.fill"
        case .heartRate: return "heart.fill"
        case .hrv: return "waveform.path.ecg"
        case .activity: return "figure.walk"
        }
    }

    var color: Color {
        switch self {
        case .recovery: return .green
        case .strain: return .orange
        case .sleep: return .purple
        case .heartRate: return .red
        case .hrv: return .blue
        case .activity: return .cyan
        }
    }
}
