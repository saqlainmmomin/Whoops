import Foundation
import SwiftData

/// LocalStore: On-device data persistence using SwiftData
/// All health data remains local - no cloud sync
struct LocalStore {

    // MARK: - Daily Metrics Operations

    static func saveDailyMetrics(_ metrics: DailyMetrics, context: ModelContext) throws {
        let startOfDay = metrics.date.startOfDay

        // Check if record already exists
        let predicate = #Predicate<DailyMetricsRecord> { record in
            record.date == startOfDay
        }
        let descriptor = FetchDescriptor<DailyMetricsRecord>(predicate: predicate)
        let existing = try context.fetch(descriptor)

        if let existingRecord = existing.first {
            // Update existing record
            existingRecord.metricsJSON = try JSONEncoder().encode(metrics)
        } else {
            // Create new record
            let record = try DailyMetricsRecord(date: startOfDay, metrics: metrics)
            context.insert(record)
        }

        try context.save()
    }

    static func fetchDailyMetrics(for date: Date, context: ModelContext) throws -> DailyMetrics? {
        let startOfDay = date.startOfDay
        let predicate = #Predicate<DailyMetricsRecord> { record in
            record.date == startOfDay
        }
        let descriptor = FetchDescriptor<DailyMetricsRecord>(predicate: predicate)
        let records = try context.fetch(descriptor)

        return try records.first?.getMetrics()
    }

    static func fetchDailyMetrics(from startDate: Date, to endDate: Date, context: ModelContext) throws -> [DailyMetrics] {
        let start = startDate.startOfDay
        let end = endDate.endOfDay

        let predicate = #Predicate<DailyMetricsRecord> { record in
            record.date >= start && record.date <= end
        }

        var descriptor = FetchDescriptor<DailyMetricsRecord>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.date, order: .forward)]

        let records = try context.fetch(descriptor)
        return records.compactMap { try? $0.getMetrics() }
    }

    static func fetchRecentMetrics(days: Int, context: ModelContext) throws -> [DailyMetrics] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return try fetchDailyMetrics(from: startDate, to: Date(), context: context)
    }

    // MARK: - Baseline Operations

    static func saveBaseline(_ baseline: Baseline, context: ModelContext) throws {
        let record = try BaselineRecord(baseline: baseline)
        let recordId = record.id

        // Check for existing
        let predicate = #Predicate<BaselineRecord> { r in
            r.id == recordId
        }
        let descriptor = FetchDescriptor<BaselineRecord>(predicate: predicate)
        let existing = try context.fetch(descriptor)

        if let existingRecord = existing.first {
            existingRecord.baselineJSON = record.baselineJSON
        } else {
            context.insert(record)
        }

        try context.save()
    }

    static func fetchBaseline(windowDays: Int, for date: Date, context: ModelContext) throws -> Baseline? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        let id = "\(windowDays)day-\(dateString)"

        let predicate = #Predicate<BaselineRecord> { record in
            record.id == id
        }
        let descriptor = FetchDescriptor<BaselineRecord>(predicate: predicate)
        let records = try context.fetch(descriptor)

        return try records.first?.getBaseline()
    }

    static func fetchLatestBaseline(windowDays: Int, context: ModelContext) throws -> Baseline? {
        let prefix = "\(windowDays)day-"

        // Fetch all baseline records and filter in memory
        var descriptor = FetchDescriptor<BaselineRecord>()
        descriptor.sortBy = [SortDescriptor(\.id, order: .reverse)]

        let allRecords = try context.fetch(descriptor)
        let matchingRecords = allRecords.filter { $0.id.hasPrefix(prefix) }

        return try matchingRecords.first?.getBaseline()
    }

    // MARK: - Cleanup Operations

    static func deleteOldRecords(olderThan days: Int, context: ModelContext) throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

        let predicate = #Predicate<DailyMetricsRecord> { record in
            record.date < cutoffDate
        }
        let descriptor = FetchDescriptor<DailyMetricsRecord>(predicate: predicate)
        let oldRecords = try context.fetch(descriptor)

        for record in oldRecords {
            context.delete(record)
        }

        try context.save()
    }

    static func deleteAllData(context: ModelContext) throws {
        // Delete all metrics
        let metricsDescriptor = FetchDescriptor<DailyMetricsRecord>()
        let allMetrics = try context.fetch(metricsDescriptor)
        for record in allMetrics {
            context.delete(record)
        }

        // Delete all baselines
        let baselineDescriptor = FetchDescriptor<BaselineRecord>()
        let allBaselines = try context.fetch(baselineDescriptor)
        for record in allBaselines {
            context.delete(record)
        }

        try context.save()
    }

    // MARK: - Statistics

    static func getRecordCount(context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<DailyMetricsRecord>()
        return try context.fetchCount(descriptor)
    }

    static func getDateRange(context: ModelContext) throws -> (earliest: Date, latest: Date)? {
        var descriptor = FetchDescriptor<DailyMetricsRecord>()
        descriptor.sortBy = [SortDescriptor(\.date, order: .forward)]
        descriptor.fetchLimit = 1

        guard let earliest = try context.fetch(descriptor).first?.date else {
            return nil
        }

        descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        guard let latest = try context.fetch(descriptor).first?.date else {
            return nil
        }

        return (earliest, latest)
    }
}

// MARK: - Batch Operations

extension LocalStore {

    static func batchSaveMetrics(_ metricsArray: [DailyMetrics], context: ModelContext) throws {
        for metrics in metricsArray {
            try saveDailyMetrics(metrics, context: context)
        }
    }

    static func fetchMetricsWithGaps(context: ModelContext, maxDays: Int = 90) throws -> [Date] {
        let startDate = Calendar.current.date(byAdding: .day, value: -maxDays, to: Date())!
        let allDates = Set(DateHelpers.dates(from: startDate, to: Date()))

        let predicate = #Predicate<DailyMetricsRecord> { record in
            record.date >= startDate
        }
        let descriptor = FetchDescriptor<DailyMetricsRecord>(predicate: predicate)
        let records = try context.fetch(descriptor)
        let recordedDates = Set(records.map { $0.date.startOfDay })

        return allDates.subtracting(recordedDates).sorted()
    }
}
