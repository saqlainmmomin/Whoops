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
        recordCount = (try? LocalStore.getRecordCount(context: modelContext)) ?? 0
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
        let days = range.days ?? 365
        let pipeline = DailyAssessmentPipeline(healthKitManager: healthKitManager)
        let result = try await pipeline.loadHistory(days: days, endingOn: Date(), context: modelContext)
        return result.dailyMetrics
    }
}
