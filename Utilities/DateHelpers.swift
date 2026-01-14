import Foundation

struct DateHelpers {

    // MARK: - Calendar Instance

    static var calendar: Calendar { Calendar.current }

    // MARK: - Day Operations

    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    static func endOfDay(_ date: Date) -> Date {
        calendar.date(byAdding: .day, value: 1, to: startOfDay(date))!
    }

    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }

    static func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    static func isYesterday(_ date: Date) -> Bool {
        calendar.isDateInYesterday(date)
    }

    // MARK: - Date Ranges

    static func dayRange(for date: Date) -> DateInterval {
        DateInterval(start: startOfDay(date), end: endOfDay(date))
    }

    static func weekRange(ending date: Date) -> DateInterval {
        let end = endOfDay(date)
        let start = calendar.date(byAdding: .day, value: -7, to: startOfDay(date))!
        return DateInterval(start: start, end: end)
    }

    static func monthRange(ending date: Date) -> DateInterval {
        let end = endOfDay(date)
        let start = calendar.date(byAdding: .day, value: -28, to: startOfDay(date))!
        return DateInterval(start: start, end: end)
    }

    static func last(days: Int, from date: Date = Date()) -> DateInterval {
        let end = endOfDay(date)
        let start = calendar.date(byAdding: .day, value: -days, to: startOfDay(date))!
        return DateInterval(start: start, end: end)
    }

    // MARK: - Date Iteration

    static func dates(from startDate: Date, to endDate: Date) -> [Date] {
        var dates: [Date] = []
        var currentDate = startOfDay(startDate)
        let end = startOfDay(endDate)

        while currentDate <= end {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return dates
    }

    static func datesInLast(days: Int, from date: Date = Date()) -> [Date] {
        let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: date)!
        return dates(from: startDate, to: date)
    }

    // MARK: - Sleep Window

    // Sleep window for a given date: 6pm previous day to 12pm current day
    static func sleepWindow(for date: Date) -> DateInterval {
        let startOfTargetDay = startOfDay(date)
        let sleepStart = calendar.date(byAdding: .hour, value: -6, to: startOfTargetDay)!  // 6pm previous
        let sleepEnd = calendar.date(byAdding: .hour, value: 12, to: startOfTargetDay)!   // 12pm current
        return DateInterval(start: sleepStart, end: sleepEnd)
    }

    // MARK: - Time Components

    static func hour(of date: Date) -> Int {
        calendar.component(.hour, from: date)
    }

    static func minute(of date: Date) -> Int {
        calendar.component(.minute, from: date)
    }

    static func minutesSinceMidnight(_ date: Date) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    // MARK: - Formatting

    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    static func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    static func formatDayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    static func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    static func formatDurationHours(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60

        if h > 0 {
            return "\(h)h \(m)m"
        }
        return "\(m)m"
    }

    // MARK: - Relative Formatting

    static func relativeDescription(_ date: Date) -> String {
        if isToday(date) {
            return "Today"
        } else if isYesterday(date) {
            return "Yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: startOfDay(date), to: startOfDay(Date())).day ?? 0
            if days < 7 {
                return formatDayOfWeek(date)
            } else {
                return formatShortDate(date)
            }
        }
    }

    // MARK: - Week Boundaries

    static func startOfWeek(_ date: Date) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components)!
    }

    static func endOfWeek(_ date: Date) -> Date {
        calendar.date(byAdding: .day, value: 7, to: startOfWeek(date))!
    }

    // MARK: - Age Calculation

    static func daysSince(_ date: Date, from referenceDate: Date = Date()) -> Int {
        calendar.dateComponents([.day], from: startOfDay(date), to: startOfDay(referenceDate)).day ?? 0
    }

    static func hoursSince(_ date: Date, from referenceDate: Date = Date()) -> Int {
        calendar.dateComponents([.hour], from: date, to: referenceDate).hour ?? 0
    }
}

// MARK: - Date Extensions

extension Date {
    var startOfDay: Date { DateHelpers.startOfDay(self) }
    var endOfDay: Date { DateHelpers.endOfDay(self) }

    var isToday: Bool { DateHelpers.isToday(self) }
    var isYesterday: Bool { DateHelpers.isYesterday(self) }

    var dayRange: DateInterval { DateHelpers.dayRange(for: self) }
    var sleepWindow: DateInterval { DateHelpers.sleepWindow(for: self) }

    var formattedTime: String { DateHelpers.formatTime(self) }
    var formattedDate: String { DateHelpers.formatDate(self) }
    var formattedShortDate: String { DateHelpers.formatShortDate(self) }
    var relativeDescription: String { DateHelpers.relativeDescription(self) }

    func isSameDay(as other: Date) -> Bool {
        DateHelpers.isSameDay(self, other)
    }

    func daysSince(_ other: Date) -> Int {
        DateHelpers.daysSince(other, from: self)
    }

    func adding(days: Int) -> Date {
        DateHelpers.calendar.date(byAdding: .day, value: days, to: self)!
    }

    func adding(hours: Int) -> Date {
        DateHelpers.calendar.date(byAdding: .hour, value: hours, to: self)!
    }
}
