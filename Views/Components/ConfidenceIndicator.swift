import SwiftUI

struct ConfidenceIndicator: View {
    let confidence: Confidence
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: confidence.icon)
                .font(compact ? .caption2 : .caption)

            if !compact {
                Text(confidence.rawValue)
                    .font(.caption)
            }
        }
        .foregroundColor(confidenceColor)
        .padding(.horizontal, compact ? 4 : 8)
        .padding(.vertical, compact ? 2 : 4)
        .background(confidenceColor.opacity(0.1))
        .cornerRadius(compact ? 4 : 8)
    }

    private var confidenceColor: Color {
        switch confidence {
        case .low: return .orange
        case .medium: return .secondary
        case .high: return .green
        }
    }
}

// MARK: - Confidence Dots

struct ConfidenceDots: View {
    let confidence: Confidence

    private var filledDots: Int {
        switch confidence {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(index < filledDots ? dotColor : Color(.systemGray4))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private var dotColor: Color {
        switch confidence {
        case .low: return .orange
        case .medium: return .yellow
        case .high: return .green
        }
    }
}

// MARK: - Confidence Label

struct ConfidenceLabel: View {
    let confidence: Confidence

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                ConfidenceDots(confidence: confidence)

                Text(confidence.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(confidenceColor)
            }

            Text(confidence.description)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var confidenceColor: Color {
        switch confidence {
        case .low: return .orange
        case .medium: return .secondary
        case .high: return .green
        }
    }
}

// MARK: - Data Quality Badge

struct DataQualityBadge: View {
    let quality: DataQuality

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(qualityColor)
                .frame(width: 8, height: 8)

            Text(quality.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    private var qualityColor: Color {
        switch quality {
        case .poor: return .red
        case .fair: return .orange
        case .good: return .yellow
        case .excellent: return .green
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        // Confidence Indicators
        HStack(spacing: 16) {
            ConfidenceIndicator(confidence: .low)
            ConfidenceIndicator(confidence: .medium)
            ConfidenceIndicator(confidence: .high)
        }

        // Compact
        HStack(spacing: 16) {
            ConfidenceIndicator(confidence: .low, compact: true)
            ConfidenceIndicator(confidence: .medium, compact: true)
            ConfidenceIndicator(confidence: .high, compact: true)
        }

        // Confidence Dots
        HStack(spacing: 24) {
            ConfidenceDots(confidence: .low)
            ConfidenceDots(confidence: .medium)
            ConfidenceDots(confidence: .high)
        }

        // Confidence Labels
        VStack(alignment: .leading, spacing: 12) {
            ConfidenceLabel(confidence: .low)
            ConfidenceLabel(confidence: .medium)
            ConfidenceLabel(confidence: .high)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)

        // Data Quality Badges
        HStack(spacing: 8) {
            DataQualityBadge(quality: .poor)
            DataQualityBadge(quality: .fair)
            DataQualityBadge(quality: .good)
            DataQualityBadge(quality: .excellent)
        }
    }
    .padding()
}
