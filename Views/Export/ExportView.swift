import SwiftUI
import Combine
import SwiftData
import UniformTypeIdentifiers

struct ExportView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ExportViewModel()

    @State private var selectedFormat: ExportFormat = .csv
    @State private var selectedRange: ExportRange = .month
    @State private var showingShareSheet = false
    @State private var exportFile: ExportFile?

    var body: some View {
        NavigationStack {
            Form {
                // Format selection
                Section("Export Format") {
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(formatDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Date range
                Section("Date Range") {
                    Picker("Range", selection: $selectedRange) {
                        ForEach(ExportRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }

                    if let count = viewModel.recordCount {
                        Text("\(count) days of data available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Data preview
                Section("Data Included") {
                    dataIncludedRow("Recovery Score", included: true)
                    dataIncludedRow("Strain Score", included: true)
                    dataIncludedRow("Sleep Data", included: true)
                    dataIncludedRow("Heart Rate & HRV", included: true)
                    dataIncludedRow("Activity & Steps", included: true)
                    dataIncludedRow("Workout Details", included: true)
                    dataIncludedRow("HR Zone Distribution", included: true)
                    dataIncludedRow("Baseline Deviations", included: true)
                }

                // Export button
                Section {
                    Button {
                        Task {
                            await exportData()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(viewModel.isExporting ? "Exporting..." : "Export Data")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isExporting)
                }

                // Summary report
                Section("Quick Summary") {
                    Button {
                        Task {
                            await generateSummary()
                        }
                    } label: {
                        Label("Generate Summary Report", systemImage: "doc.text")
                    }
                }

                // Error message
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Export")
            .sheet(isPresented: $showingShareSheet) {
                if let file = exportFile {
                    ShareSheet(items: [createTemporaryFile(from: file)])
                }
            }
            .sheet(isPresented: $viewModel.showingSummary) {
                SummaryReportView(summary: viewModel.summaryReport ?? "")
            }
        }
        .task {
            await viewModel.loadRecordCount(modelContext: modelContext)
        }
    }

    // MARK: - Helpers

    private var formatDescription: String {
        switch selectedFormat {
        case .csv:
            return "Comma-separated values. Open in Excel, Numbers, or Google Sheets."
        case .json:
            return "Structured data format. Ideal for developers and data analysis tools."
        }
    }

    private func dataIncludedRow(_ label: String, included: Bool) -> some View {
        HStack {
            Text(label)
            Spacer()
            Image(systemName: included ? "checkmark.circle.fill" : "circle")
                .foregroundColor(included ? .green : .secondary)
        }
    }

    private func exportData() async {
        await viewModel.exportData(
            format: selectedFormat,
            range: selectedRange,
            healthKitManager: healthKitManager,
            modelContext: modelContext
        )

        if let file = viewModel.exportFile {
            exportFile = file
            showingShareSheet = true
        }
    }

    private func generateSummary() async {
        await viewModel.generateSummary(
            range: selectedRange,
            healthKitManager: healthKitManager,
            modelContext: modelContext
        )
    }

    private func createTemporaryFile(from exportFile: ExportFile) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(exportFile.filename)

        try? exportFile.content.write(to: fileURL)
        return fileURL
    }
}

// MARK: - Export Range

enum ExportRange: String, CaseIterable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case all = "all"

    var displayName: String {
        switch self {
        case .week: return "Last 7 Days"
        case .month: return "Last 28 Days"
        case .quarter: return "Last 90 Days"
        case .all: return "All Data"
        }
    }

    var days: Int? {
        switch self {
        case .week: return 7
        case .month: return 28
        case .quarter: return 90
        case .all: return nil
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Summary Report View

struct SummaryReportView: View {
    let summary: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(summary)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Summary Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: summary) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

#Preview {
    ExportView()
        .environmentObject(HealthKitManager())
}
