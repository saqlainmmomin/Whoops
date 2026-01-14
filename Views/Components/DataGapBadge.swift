import SwiftUI

/// Low-key indicator for data gaps and quality issues
struct DataGapBadge: View {
    let gaps: [String]

    var body: some View {
        if !gaps.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption)

                Text(gaps.count == 1 ? gaps[0] : "\(gaps.count) data gaps")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

// MARK: - Inline Gap Indicator

struct InlineGapIndicator: View {
    let isComplete: Bool

    var body: some View {
        if !isComplete {
            Image(systemName: "exclamationmark.circle")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Data Completeness Bar

struct DataCompletenessBar: View {
    let completeness: Double // 0-1

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Data Quality")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(completeness * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .cornerRadius(2)

                    Rectangle()
                        .fill(completenessColor)
                        .frame(width: geometry.size.width * completeness)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
        }
    }

    private var completenessColor: Color {
        switch completeness {
        case ..<0.5: return .orange
        case 0.5..<0.75: return .yellow
        default: return .green
        }
    }
}

// MARK: - Missing Data Notice

struct MissingDataNotice: View {
    let metricName: String
    let reason: String?

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.secondary)

                Text("\(metricName) unavailable")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let reason = reason {
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Gap Summary Card

struct GapSummaryCard: View {
    let dataQuality: DataQualityIndicator

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundColor(.secondary)

                Text("Data Summary")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                DataQualityBadge(quality: dataQuality.overallQuality)
            }

            VStack(spacing: 8) {
                dataRow("Heart Rate", completeness: dataQuality.heartRateCompleteness)
                dataRow("HRV", completeness: dataQuality.hrvCompleteness)
                dataRow("Sleep", completeness: dataQuality.sleepCompleteness)
                dataRow("Activity", completeness: dataQuality.activityCompleteness)
            }

            if !dataQuality.gapDescriptions.isEmpty {
                Divider()

                ForEach(dataQuality.gapDescriptions, id: \.self) { gap in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 4, height: 4)

                        Text(gap)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func dataRow(_ label: String, completeness: Double) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            LinearMetricGauge(
                value: completeness,
                maxValue: 1,
                color: completenessColor(completeness),
                height: 4
            )
            .frame(width: 60)

            Text("\(Int(completeness * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 35, alignment: .trailing)
        }
    }

    private func completenessColor(_ value: Double) -> Color {
        switch value {
        case ..<0.5: return .orange
        case 0.5..<0.75: return .yellow
        default: return .green
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        DataGapBadge(gaps: ["HRV data sparse"])
        DataGapBadge(gaps: ["HRV sparse", "Sleep incomplete", "Activity missing"])
        DataGapBadge(gaps: [])

        DataCompletenessBar(completeness: 0.85)
        DataCompletenessBar(completeness: 0.6)
        DataCompletenessBar(completeness: 0.3)

        MissingDataNotice(
            metricName: "HRV",
            reason: "Wear your Apple Watch during sleep for HRV measurements"
        )

        GapSummaryCard(
            dataQuality: DataQualityIndicator(
                heartRateCompleteness: 0.9,
                hrvCompleteness: 0.6,
                sleepCompleteness: 0.8,
                activityCompleteness: 1.0
            )
        )
    }
    .padding()
}
