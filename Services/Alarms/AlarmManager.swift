import Foundation
import UserNotifications
import SwiftUI
import UIKit
import Combine

/// Manages smart alarm notifications and bedtime planning
/// Since iOS doesn't allow direct Clock app integration, we use:
/// 1. Smart notifications with persistent sound for wake-up
/// 2. Deep link button to open Clock app for native alarms
/// 3. AppStorage for alarm preferences
@MainActor
class AlarmManager: ObservableObject {
    static let shared = AlarmManager()

    @Published var isAuthorized = false

    // Alarm preferences
    @AppStorage("alarm.enabled") var alarmEnabled = false
    @AppStorage("alarm.hour") var alarmHour = 7
    @AppStorage("alarm.minute") var alarmMinute = 0
    @AppStorage("alarm.smartWakeEnabled") var smartWakeEnabled = true
    @AppStorage("alarm.smartWakeWindowMinutes") var smartWakeWindowMinutes = 15

    // Bedtime preferences
    @AppStorage("bedtime.enabled") var bedtimeEnabled = false
    @AppStorage("bedtime.hour") var bedtimeHour = 22
    @AppStorage("bedtime.minute") var bedtimeMinute = 30
    @AppStorage("bedtime.reminderMinutesBefore") var reminderMinutesBefore = 30

    private let center = UNUserNotificationCenter.current()

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            // Request with critical alerts if available (requires entitlement)
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            return granted
        } catch {
            print("Alarm authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Alarm Time Formatting

    var alarmTimeFormatted: String {
        let components = DateComponents(hour: alarmHour, minute: alarmMinute)
        let date = Calendar.current.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    var bedtimeFormatted: String {
        let components = DateComponents(hour: bedtimeHour, minute: bedtimeMinute)
        let date = Calendar.current.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    var alarmDate: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = alarmHour
        components.minute = alarmMinute
        return Calendar.current.date(from: components) ?? Date()
    }

    var bedtimeDate: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = bedtimeHour
        components.minute = bedtimeMinute
        return Calendar.current.date(from: components) ?? Date()
    }

    // MARK: - Set Alarm

    func setAlarm(hour: Int, minute: Int) {
        alarmHour = hour
        alarmMinute = minute

        if alarmEnabled {
            scheduleAlarmNotification()
        }
    }

    func setBedtime(hour: Int, minute: Int) {
        bedtimeHour = hour
        bedtimeMinute = minute

        if bedtimeEnabled {
            scheduleBedtimeReminder()
        }
    }

    func toggleAlarm(_ enabled: Bool) {
        alarmEnabled = enabled
        if enabled {
            scheduleAlarmNotification()
        } else {
            cancelAlarmNotification()
        }
    }

    func toggleBedtime(_ enabled: Bool) {
        bedtimeEnabled = enabled
        if enabled {
            scheduleBedtimeReminder()
        } else {
            cancelBedtimeReminder()
        }
    }

    // MARK: - Smart Wake Notification

    /// Schedules a repeating alarm notification
    func scheduleAlarmNotification() {
        guard alarmEnabled else {
            cancelAlarmNotification()
            return
        }

        var dateComponents = DateComponents()
        dateComponents.hour = alarmHour
        dateComponents.minute = alarmMinute

        let content = UNMutableNotificationContent()
        content.title = "Wake Up"
        content.body = "Time to start your day! Check your recovery score."
        content.sound = UNNotificationSound.defaultCritical
        content.categoryIdentifier = NotificationCategory.alarm.rawValue
        content.interruptionLevel = .timeSensitive

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "smartAlarm",
            content: content,
            trigger: trigger
        )

        Task {
            // Remove old alarm first
            center.removePendingNotificationRequests(withIdentifiers: ["smartAlarm"])
            try? await center.add(request)
        }
    }

    func cancelAlarmNotification() {
        center.removePendingNotificationRequests(withIdentifiers: ["smartAlarm"])
    }

    // MARK: - Bedtime Reminder

    func scheduleBedtimeReminder() {
        guard bedtimeEnabled else {
            cancelBedtimeReminder()
            return
        }

        // Calculate reminder time (X minutes before bedtime)
        var reminderHour = bedtimeHour
        var reminderMinute = bedtimeMinute - reminderMinutesBefore

        // Handle negative minutes
        while reminderMinute < 0 {
            reminderMinute += 60
            reminderHour -= 1
            if reminderHour < 0 {
                reminderHour += 24
            }
        }

        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute

        let content = UNMutableNotificationContent()
        content.title = "Bedtime Approaching"
        content.body = "Start winding down. Good sleep leads to better recovery."
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.bedtime.rawValue

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "bedtimeReminder",
            content: content,
            trigger: trigger
        )

        Task {
            center.removePendingNotificationRequests(withIdentifiers: ["bedtimeReminder"])
            try? await center.add(request)
        }
    }

    func cancelBedtimeReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["bedtimeReminder"])
    }

    // MARK: - Deep Link to Clock App

    /// Opens the Clock app. Note: iOS doesn't have a direct deep link to Clock,
    /// so this opens Settings as a fallback
    func openClockApp() {
        // Try to open Clock app via URL scheme
        if let clockURL = URL(string: "clock-alarm://") {
            if UIApplication.shared.canOpenURL(clockURL) {
                UIApplication.shared.open(clockURL)
                return
            }
        }

        // Fallback: open Settings
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }

    // MARK: - Calculate Optimal Bedtime

    /// Calculate optimal bedtime based on alarm time and sleep need
    func calculateOptimalBedtime(sleepNeedHours: Double = 7.5) -> Date {
        let sleepNeedSeconds = sleepNeedHours * 3600
        let windDownMinutes: TimeInterval = 15 * 60 // 15 minutes to fall asleep

        var alarmComponents = DateComponents()
        alarmComponents.hour = alarmHour
        alarmComponents.minute = alarmMinute

        let today = Calendar.current.startOfDay(for: Date())
        var alarmDate = Calendar.current.date(byAdding: alarmComponents, to: today)!

        // If alarm time is earlier than current time, it's for tomorrow
        if alarmDate < Date() {
            alarmDate = Calendar.current.date(byAdding: .day, value: 1, to: alarmDate)!
        }

        // Calculate bedtime = alarm time - sleep need - wind down time
        return alarmDate.addingTimeInterval(-(sleepNeedSeconds + windDownMinutes))
    }

    // MARK: - Setup All Alarms

    func setupAllAlarms() {
        if alarmEnabled {
            scheduleAlarmNotification()
        }
        if bedtimeEnabled {
            scheduleBedtimeReminder()
        }
    }

    func cancelAllAlarms() {
        cancelAlarmNotification()
        cancelBedtimeReminder()
    }
}

// MARK: - Notification Category Extension

extension NotificationCategory {
    static let alarm = NotificationCategory(rawValue: "ALARM_CATEGORY")!
}
