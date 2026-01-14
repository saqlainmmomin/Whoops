import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class ExportViewModel: ObservableObject {
    @Published var isExporting = false
    @Published var errorMessage: String?
    @Published var exportFile: ExportFile?
    @Published var recordCount: Int?
    @Published var showingSummary = false
    @Published var summaryReport: String?

    // MARK: - Load Record Count

    func loadRecordCount(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<DailyMetricsRecord>()
        do {
            let records = try modelContext.fetch(descriptor)
            recordCount = records.count
        } catch {
            recordCount = 0
        }
    }

    // MARK: - Export Data

    func exportData(
        format: ExportFormat,
        range: ExportRange,
        healthKitManager: HealthKitManager,
        modelContext: ModelContext
    ) async {
        isExporting = true
        errorMessage = nil
        exportFile = nil

        do {
            let metrics = try await loadMetrics(
                range: range,
                healthKitManager: healthKitManager,
                modelContext: modelContext
            )

            guard !metrics.isEmpty else {
                throw ExportError.noData
            }

            let dateRangeString = range.displayName.replacingOccurrences(of: " ", with: "_")

            let file = try ExportService.generateExportFile(
                metrics: metrics,
                format: format,
                dateRange: dateRangeString
            )

            exportFile = file

        } catch {
            errorMessage = error.localizedDescription
        }

        isExporting = false
    }

    // MARK: - Generate Summary

    func generateSummary(
        range: ExportRange,
        healthKitManager: HealthKitManager,
        modelContext: ModelContext
    ) async {
        isExporting = true
        errorMessage = nil

        do {
            let metrics = try await loadMetrics(
                range: range,
                healthKitManager: healthKitManager,
                modelContext: modelContext
            )

            summaryReport = ExportService.generateSummaryReport(metrics: metrics)
            showingSummary = true

        } catch {
            errorMessage = error.localizedDescription
        }

        isExporting = false
    }

    // MARK: - Load Metrics

    private func loadMetrics(
        range: ExportRange,
        healthKitManager: HealthKitManager,
        modelContext: ModelContext
    ) async throws -> [DailyMetrics] {
        // First try to load from cache
        var metrics = try await loadCachedMetrics(range: range, modelContext: modelContext)

        // If we need more data, fetch from HealthKit
        if metrics.count < (range.days ?? 365) {
            let days = range.days ?? 365
            let dates = DateHelpers.datesInLast(days: days, from: Date())

            for date in dates {
                // Skip if already cached
                if metrics.contains(where: { $0.date.isSameDay(as: date) }) {
                    continue
                }

                // Fetch from HealthKit
                let rawData = try await healthKitManager.fetchDailyData(for: date)
                let processed = processRawData(rawData)
                metrics.append(processed)

                // Cache for future use
                await cacheMetrics(processed, context: modelContext)
            }
        }

        return metrics
    }

    private func loadCachedMetrics(range: ExportRange, modelContext: ModelContext) async throws -> [DailyMetrics] {
        var predicate: Predicate<DailyMetricsRecord>?

        if let days = range.days {
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
            predicate = #Predicate<DailyMetricsRecord> { record in
                record.date >= startDate
            }
        }

        var descriptor = FetchDescriptor<DailyMetricsRecord>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]

        let records = try modelContext.fetch(descriptor)
        return records.compactMap { try? $0.getMetrics() }
    }

    private func processRawData(_ raw: RawDailyHealthData) -> DailyMetrics {
        let date = raw.date
        let sleepWindow = DateHelpers.sleepWindow(for: date)

        let heartRateSummary = Tier1Calculator.calculateHeartRateSummary(
            heartRateSamples: raw.heartRateSamples,
            restingHRSamples: raw.restingHeartRateSamples,
            for: date
        )

        let hrvSummary = Tier1Calculator.calculateHRVSummary(
            hrvSamples: raw.hrvSamples,
            sleepWindow: sleepWindow,
            for: date
        )

        let sleepSummary = Tier1Calculator.calculateSleepSummary(
            sleepSamples: raw.sleepSamples,
            for: date
        )

        let workoutSummary = Tier1Calculator.calculateWorkoutSummary(
            workouts: raw.workouts,
            for: date
        )

        let activitySummary = Tier1Calculator.calculateActivitySummary(
            steps: raw.steps,
            distance: raw.distance,
            activeEnergy: raw.activeEnergy,
            basalEnergy: raw.basalEnergy,
            for: date
        )

        let zoneDistribution = Tier1Calculator.calculateZoneDistribution(
            heartRateSamples: raw.heartRateSamples,
            maxHeartRate: Constants.HeartRateZones.defaultMaxHR
        )

        let dataQuality = Tier1Calculator.assessDataQuality(
            heartRateSamples: raw.heartRateSamples,
            hrvSamples: raw.hrvSamples,
            sleepSummary: sleepSummary,
            activitySummary: activitySummary
        )

        return DailyMetrics(
            date: date,
            heartRate: heartRateSummary,
            hrv: hrvSummary,
            sleep: sleepSummary,
            workouts: workoutSummary,
            activity: activitySummary,
            zoneDistribution: zoneDistribution,
            hrRecovery: nil,
            acuteLoad: nil,
            chronicLoad: nil,
            loadRatio: nil,
            sleepDebt: nil,
            hrvDeviation: nil,
            rhrDeviation: nil,
            sleepTimingConsistency: nil,
            recoveryScore: nil,
            strainScore: nil,
            dataQuality: dataQuality
        )
    }

    private func cacheMetrics(_ metrics: DailyMetrics, context: ModelContext) async {
        do {
            let record = try DailyMetricsRecord(date: metrics.date.startOfDay, metrics: metrics)
            context.insert(record)
            try context.save()
        } catch {
            print("Failed to cache metrics: \(error)")
        }
    }
}
