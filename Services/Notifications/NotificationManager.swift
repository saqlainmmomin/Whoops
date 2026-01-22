import Foundation
import UserNotifications
import SwiftUI
import Combine

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // User preferences
    @AppStorage("notifications.lowRecoveryAlert") var lowRecoveryAlertEnabled = true
    @AppStorage("notifications.bedtimeReminder") var bedtimeReminderEnabled = true
    @AppStorage("notifications.weeklyDigest") var weeklyDigestEnabled = true
    @AppStorage("notifications.bedtimeHour") var bedtimeHour = 22
    @AppStorage("notifications.bedtimeMinute") var bedtimeMinute = 30

    private let center = UNUserNotificationCenter.current()

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Low Recovery Alert

    func scheduleLowRecoveryAlert(recoveryScore: Int, for date: Date = Date()) {
        guard lowRecoveryAlertEnabled, recoveryScore < 33 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Low Recovery Alert"
        content.body = "Your recovery is at \(recoveryScore)%. Consider taking it easy today and prioritizing rest."
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.recovery.rawValue

        // Schedule for 8 AM if not already past
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = 8
        dateComponents.minute = 0

        let scheduledDate = Calendar.current.date(from: dateComponents) ?? date

        // Only schedule if it's in the future
        guard scheduledDate > Date() else { return }

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "lowRecovery-\(date.formatted(.iso8601))",
            content: content,
            trigger: trigger
        )

        Task {
            try? await center.add(request)
        }
    }

    // MARK: - Bedtime Reminder

    func scheduleBedtimeReminder() {
        guard bedtimeReminderEnabled else {
            cancelBedtimeReminder()
            return
        }

        // Calculate reminder time (30 min before bedtime)
        var reminderComponents = DateComponents()
        reminderComponents.hour = bedtimeHour
        reminderComponents.minute = bedtimeMinute - 30

        // Handle negative minutes
        if reminderComponents.minute! < 0 {
            reminderComponents.minute! += 60
            reminderComponents.hour! -= 1
            if reminderComponents.hour! < 0 {
                reminderComponents.hour! += 24
            }
        }

        let content = UNMutableNotificationContent()
        content.title = "Bedtime Approaching"
        content.body = "Time to start winding down. Good sleep leads to better recovery tomorrow."
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.bedtime.rawValue

        let trigger = UNCalendarNotificationTrigger(dateMatching: reminderComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "bedtimeReminder",
            content: content,
            trigger: trigger
        )

        Task {
            try? await center.add(request)
        }
    }

    func cancelBedtimeReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["bedtimeReminder"])
    }

    // MARK: - Weekly Digest

    func scheduleWeeklyDigest() {
        guard weeklyDigestEnabled else {
            cancelWeeklyDigest()
            return
        }

        // Schedule for Sunday at 9 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 9
        dateComponents.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Weekly Health Summary"
        content.body = "Your weekly report is ready. See how your recovery, strain, and sleep compared to last week."
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.weeklyDigest.rawValue

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weeklyDigest",
            content: content,
            trigger: trigger
        )

        Task {
            try? await center.add(request)
        }
    }

    func cancelWeeklyDigest() {
        center.removePendingNotificationRequests(withIdentifiers: ["weeklyDigest"])
    }

    // MARK: - Setup All Recurring Notifications

    func setupRecurringNotifications() {
        if bedtimeReminderEnabled {
            scheduleBedtimeReminder()
        }
        if weeklyDigestEnabled {
            scheduleWeeklyDigest()
        }
    }

    // MARK: - Cancel All

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Update Preferences

    func updateBedtimeReminder(hour: Int, minute: Int) {
        bedtimeHour = hour
        bedtimeMinute = minute
        if bedtimeReminderEnabled {
            scheduleBedtimeReminder()
        }
    }

    func toggleLowRecoveryAlert(_ enabled: Bool) {
        lowRecoveryAlertEnabled = enabled
    }

    func toggleBedtimeReminder(_ enabled: Bool) {
        bedtimeReminderEnabled = enabled
        if enabled {
            scheduleBedtimeReminder()
        } else {
            cancelBedtimeReminder()
        }
    }

    func toggleWeeklyDigest(_ enabled: Bool) {
        weeklyDigestEnabled = enabled
        if enabled {
            scheduleWeeklyDigest()
        } else {
            cancelWeeklyDigest()
        }
    }
}

// MARK: - Session 7: New Insight Notifications

extension NotificationManager {

    /// Generate specific insight notification based on metrics
    /// Returns nil if no actionable insight
    func generateInsightNotification(for metrics: DailyMetrics) -> UNNotificationContent? {
        let content = UNMutableNotificationContent()

        // HRV-based insight (SPECIFIC, not vague)
        // Use hrvDeviation which is already calculated as a percentage/z-score
        if let hrvDeviation = metrics.hrvDeviation {
            // Convert z-score to approximate percentage for display
            let deviationPercent = hrvDeviation * 10 // Rough approximation

            if deviationPercent >= 16 {
                content.title = "Elevated HRV"
                content.body = "HRV \(Int(deviationPercent))% above baseline. Consider high-intensity session."
                content.sound = .default
                content.categoryIdentifier = NotificationCategory.insight.rawValue
                return content
            }

            if deviationPercent <= -20 {
                content.title = "HRV Below Baseline"
                content.body = "HRV \(Int(abs(deviationPercent)))% below baseline. Prioritize recovery today."
                content.sound = .default
                content.categoryIdentifier = NotificationCategory.insight.rawValue
                return content
            }
        }

        // Low recovery suppression
        if let recovery = metrics.recoveryScore,
           recovery.score < 50 {
            content.title = "Low Recovery Detected"
            content.body = "Prioritize rest today. Recovery at \(recovery.score)%."
            content.sound = .default
            content.categoryIdentifier = NotificationCategory.recovery.rawValue
            return content
        }

        // High strain alert
        if let strain = metrics.strainScore,
           strain.score > 1700 { // >17 on 0-21 scale
            content.title = "High Strain Day"
            content.body = "You've accumulated significant strain. Consider winding down."
            content.sound = .default
            content.categoryIdentifier = NotificationCategory.strain.rawValue
            return content
        }

        return nil
    }

    /// Schedule insight notification if warranted
    func scheduleInsightNotification(for metrics: DailyMetrics) {
        guard let content = generateInsightNotification(for: metrics) else { return }

        // Schedule for immediate delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "insight-\(metrics.date.formatted(.iso8601))",
            content: content,
            trigger: trigger
        )

        Task {
            try? await center.add(request)
        }
    }

    /// Opt-in bedtime reminder with specific target time
    func scheduleBedtimeReminder(targetBedtime: Date, enabled: Bool) {
        guard enabled else {
            cancelBedtimeReminder()
            return
        }

        let reminderTime = Calendar.current.date(byAdding: .minute, value: -30, to: targetBedtime)!

        let content = UNMutableNotificationContent()
        content.title = "Bedtime Reminder"
        content.body = "Bedtime in 30 minutes to maintain consistency."
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.bedtime.rawValue

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "bedtimeReminder",
            content: content,
            trigger: trigger
        )

        Task {
            try? await center.add(request)
        }
    }

    /// Morning recovery summary notification
    func scheduleMorningRecoverySummary(recoveryScore: Int, hrvDeviation: Double?, date: Date = Date()) {
        let content = UNMutableNotificationContent()

        // Determine message based on recovery
        if recoveryScore >= 70 {
            content.title = "Ready for Training"
            content.body = "Recovery at \(recoveryScore)%. Your body can handle high intensity today."
        } else if recoveryScore >= 34 {
            content.title = "Moderate Recovery"
            content.body = "Recovery at \(recoveryScore)%. Moderate activity recommended."
        } else {
            content.title = "Rest Day Recommended"
            content.body = "Recovery at \(recoveryScore)%. Focus on light activity and recovery."
        }

        content.sound = .default
        content.categoryIdentifier = NotificationCategory.recovery.rawValue

        // Schedule for 7 AM
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = 7
        dateComponents.minute = 0

        let scheduledDate = Calendar.current.date(from: dateComponents) ?? date
        guard scheduledDate > Date() else { return }

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "morningRecovery-\(date.formatted(.iso8601))",
            content: content,
            trigger: trigger
        )

        Task {
            try? await center.add(request)
        }
    }

    /// Sleep performance notification
    func scheduleSleepPerformanceNotification(performance: Int, hoursSlept: Double, hoursNeeded: Double) {
        guard performance < 70 else { return } // Only notify for suboptimal sleep

        let content = UNMutableNotificationContent()
        content.title = "Sleep Performance: \(performance)%"

        let deficit = hoursNeeded - hoursSlept
        if deficit > 1 {
            content.body = String(format: "You're %.1f hours short of your sleep need.", deficit)
        } else {
            content.body = "Consider improving sleep consistency for better recovery."
        }

        content.sound = .default
        content.categoryIdentifier = NotificationCategory.sleep.rawValue

        // Immediate notification
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "sleepPerformance-\(Date().formatted(.iso8601))",
            content: content,
            trigger: trigger
        )

        Task {
            try? await center.add(request)
        }
    }
}

// MARK: - Notification Categories

enum NotificationCategory: String {
    case recovery = "RECOVERY_CATEGORY"
    case bedtime = "BEDTIME_CATEGORY"
    case weeklyDigest = "WEEKLY_DIGEST_CATEGORY"
    case insight = "INSIGHT_CATEGORY"
    case strain = "STRAIN_CATEGORY"
    case sleep = "SLEEP_CATEGORY"
}
