import Foundation
import HealthKit

struct HKQueryBuilders {

    // MARK: - Predicate Builders

    static func predicateForDay(_ date: Date) -> NSPredicate {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
    }

    static func predicateForDateRange(start: Date, end: Date) -> NSPredicate {
        return HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )
    }

    static func predicateForLast(days: Int, from date: Date = Date()) -> NSPredicate {
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: date)!)
        let startDate = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: date))!

        return HKQuery.predicateForSamples(
            withStart: startDate,
            end: endOfDay,
            options: .strictStartDate
        )
    }

    // Sleep window: typically 6pm previous day to 12pm current day
    static func predicateForSleepWindow(date: Date) -> NSPredicate {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // Sleep window: 6pm previous day to 12pm current day
        let sleepWindowStart = calendar.date(byAdding: .hour, value: -6, to: startOfDay)!
        let sleepWindowEnd = calendar.date(byAdding: .hour, value: 12, to: startOfDay)!

        return HKQuery.predicateForSamples(
            withStart: sleepWindowStart,
            end: sleepWindowEnd,
            options: .strictStartDate
        )
    }

    // MARK: - Sort Descriptors

    static var sortByStartDateAscending: [NSSortDescriptor] {
        [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
    }

    static var sortByStartDateDescending: [NSSortDescriptor] {
        [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
    }

    static var sortByEndDateDescending: [NSSortDescriptor] {
        [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
    }

    // MARK: - Date Interval Helpers

    static func dayInterval(for date: Date) -> DateInterval {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return DateInterval(start: startOfDay, end: endOfDay)
    }

    static func weekInterval(ending date: Date) -> DateInterval {
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: date)!)
        let startDate = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: date))!
        return DateInterval(start: startDate, end: endOfDay)
    }

    static func monthInterval(ending date: Date) -> DateInterval {
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: date)!)
        let startDate = calendar.date(byAdding: .day, value: -28, to: calendar.startOfDay(for: date))!
        return DateInterval(start: startDate, end: endOfDay)
    }

    // MARK: - Statistics Options

    static var discreteAverageOptions: HKStatisticsOptions { .discreteAverage }
    static var discreteMinMaxOptions: HKStatisticsOptions { [.discreteMin, .discreteMax] }
    static var cumulativeSumOptions: HKStatisticsOptions { .cumulativeSum }
}
