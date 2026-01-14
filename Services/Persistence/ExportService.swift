import Foundation
import UniformTypeIdentifiers

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case json = "JSON"

    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        }
    }

    var contentType: UTType {
        switch self {
        case .csv: return .commaSeparatedText
        case .json: return .json
        }
    }
}

struct ExportService {

    // MARK: - CSV Export

    static func exportToCSV(metrics: [DailyMetrics]) -> String {
        var csv = csvHeader + "\n"

        for metric in metrics.sorted(by: { $0.date < $1.date }) {
            csv += csvRow(for: metric) + "\n"
        }

        return csv
    }

    private static var csvHeader: String {
        [
            "date",
            "recovery_score",
            "recovery_confidence",
            "strain_score",
            "strain_confidence",
            "sleep_hours",
            "sleep_efficiency",
            "deep_sleep_min",
            "core_sleep_min",
            "rem_sleep_min",
            "sleep_interruptions",
            "resting_hr_bpm",
            "hrv_sdnn_ms",
            "hrv_deviation",
            "rhr_deviation",
            "steps",
            "active_energy_kcal",
            "workout_minutes",
            "zone1_min",
            "zone2_min",
            "zone3_min",
            "zone4_min",
            "zone5_min",
            "acute_load",
            "chronic_load",
            "load_ratio",
            "data_quality"
        ].joined(separator: Constants.Export.csvDelimiter)
    }

    private static func csvRow(for metric: DailyMetrics) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.Export.dateFormat

        let values: [String] = [
            dateFormatter.string(from: metric.date),
            metric.recoveryScore?.score.description ?? "",
            metric.recoveryScore?.confidence.rawValue ?? "",
            metric.strainScore?.score.description ?? "",
            metric.strainScore?.confidence.rawValue ?? "",
            metric.sleep?.totalSleepHours.formatted(.number.precision(.fractionLength(2))) ?? "",
            metric.sleep?.averageEfficiency.formatted(.number.precision(.fractionLength(1))) ?? "",
            metric.sleep?.combinedStageBreakdown.deepMinutes.description ?? "",
            metric.sleep?.combinedStageBreakdown.coreMinutes.description ?? "",
            metric.sleep?.combinedStageBreakdown.remMinutes.description ?? "",
            metric.sleep?.totalInterruptions.description ?? "",
            metric.heartRate?.restingBPM?.formatted(.number.precision(.fractionLength(1))) ?? "",
            (metric.hrv?.nightlySDNN ?? metric.hrv?.averageSDNN)?.formatted(.number.precision(.fractionLength(1))) ?? "",
            metric.hrvDeviation?.formatted(.number.precision(.fractionLength(2))) ?? "",
            metric.rhrDeviation?.formatted(.number.precision(.fractionLength(1))) ?? "",
            metric.activity?.steps.description ?? "",
            metric.activity?.activeEnergy.formatted(.number.precision(.fractionLength(0))) ?? "",
            metric.workouts?.totalDurationMinutes.description ?? "",
            metric.zoneDistribution?.zone1Minutes.description ?? "",
            metric.zoneDistribution?.zone2Minutes.description ?? "",
            metric.zoneDistribution?.zone3Minutes.description ?? "",
            metric.zoneDistribution?.zone4Minutes.description ?? "",
            metric.zoneDistribution?.zone5Minutes.description ?? "",
            metric.acuteLoad?.formatted(.number.precision(.fractionLength(2))) ?? "",
            metric.chronicLoad?.formatted(.number.precision(.fractionLength(2))) ?? "",
            metric.loadRatio?.formatted(.number.precision(.fractionLength(2))) ?? "",
            metric.dataQuality.overallQuality.rawValue
        ]

        return values.joined(separator: Constants.Export.csvDelimiter)
    }

    // MARK: - JSON Export

    static func exportToJSON(metrics: [DailyMetrics]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let exportData = ExportData(
            exportDate: Date(),
            appVersion: "1.0.0",
            recordCount: metrics.count,
            metrics: metrics.sorted(by: { $0.date < $1.date })
        )

        return try encoder.encode(exportData)
    }

    static func exportToJSONString(metrics: [DailyMetrics]) throws -> String {
        let data = try exportToJSON(metrics: metrics)
        guard let string = String(data: data, encoding: .utf8) else {
            throw ExportError.encodingFailed
        }
        return string
    }

    // MARK: - File Generation

    static func generateExportFile(
        metrics: [DailyMetrics],
        format: ExportFormat,
        dateRange: String
    ) throws -> ExportFile {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
            .replacingOccurrences(of: "/", with: "-")

        let filename = "whoops_export_\(dateRange)_\(timestamp).\(format.fileExtension)"

        let content: Data
        switch format {
        case .csv:
            let csvString = exportToCSV(metrics: metrics)
            guard let data = csvString.data(using: .utf8) else {
                throw ExportError.encodingFailed
            }
            content = data

        case .json:
            content = try exportToJSON(metrics: metrics)
        }

        return ExportFile(
            filename: filename,
            content: content,
            contentType: format.contentType
        )
    }

    // MARK: - Summary Export

    static func generateSummaryReport(metrics: [DailyMetrics]) -> String {
        guard !metrics.isEmpty else {
            return "No data to export."
        }

        let sorted = metrics.sorted { $0.date < $1.date }
        let startDate = sorted.first!.date
        let endDate = sorted.last!.date

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        var report = """
        WHOOPS HEALTH REPORT
        ====================

        Period: \(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))
        Days: \(metrics.count)

        SUMMARY
        -------

        """

        // Recovery stats
        let recoveryScores = metrics.compactMap { $0.recoveryScore?.score }
        if !recoveryScores.isEmpty {
            report += """
            Recovery:
              Average: \(recoveryScores.reduce(0, +) / recoveryScores.count)
              Min: \(recoveryScores.min()!)
              Max: \(recoveryScores.max()!)

            """
        }

        // Strain stats
        let strainScores = metrics.compactMap { $0.strainScore?.score }
        if !strainScores.isEmpty {
            report += """
            Strain:
              Average: \(strainScores.reduce(0, +) / strainScores.count)
              Min: \(strainScores.min()!)
              Max: \(strainScores.max()!)

            """
        }

        // Sleep stats
        let sleepHours = metrics.compactMap { $0.sleep?.totalSleepHours }
        if !sleepHours.isEmpty {
            let avgSleep = sleepHours.reduce(0, +) / Double(sleepHours.count)
            report += """
            Sleep:
              Average: \(String(format: "%.1f", avgSleep)) hours
              Min: \(String(format: "%.1f", sleepHours.min()!)) hours
              Max: \(String(format: "%.1f", sleepHours.max()!)) hours

            """
        }

        // Activity stats
        let steps = metrics.compactMap { $0.activity?.steps }
        if !steps.isEmpty {
            report += """
            Activity:
              Average Steps: \(steps.reduce(0, +) / steps.count)
              Total Steps: \(steps.reduce(0, +))

            """
        }

        report += """

        Generated by Whoops on \(dateFormatter.string(from: Date()))
        """

        return report
    }
}

// MARK: - Supporting Types

struct ExportData: Codable {
    let exportDate: Date
    let appVersion: String
    let recordCount: Int
    let metrics: [DailyMetrics]
}

struct ExportFile {
    let filename: String
    let content: Data
    let contentType: UTType
}

enum ExportError: LocalizedError {
    case encodingFailed
    case noData

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode export data"
        case .noData:
            return "No data available to export"
        }
    }
}
