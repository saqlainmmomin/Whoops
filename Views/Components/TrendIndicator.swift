import SwiftUI

struct TrendIndicator: View {
    let direction: TrendDirection
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: direction.icon)
                .font(compact ? .caption : .subheadline)
                .foregroundColor(trendColor)

            if !compact {
                Text(direction.rawValue)
                    .font(.caption)
                    .foregroundColor(trendColor)
            }
        }
        .padding(.horizontal, compact ? 4 : 8)
        .padding(.vertical, compact ? 2 : 4)
        .background(trendColor.opacity(0.15))
        .cornerRadius(compact ? 4 : 8)
    }

    private var trendColor: Color {
        switch direction {
        case .improving: return .green
        case .stable: return .secondary
        case .declining: return .orange
        }
    }
}

// MARK: - Trend Arrow Only

struct TrendArrow: View {
    let direction: TrendDirection

    var body: some View {
        Image(systemName: direction.icon)
            .font(.caption)
            .foregroundColor(trendColor)
    }

    private var trendColor: Color {
        switch direction {
        case .improving: return .green
        case .stable: return .secondary
        case .declining: return .orange
        }
    }
}

// MARK: - Trend Badge

struct TrendBadge: View {
    let direction: TrendDirection
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: direction.icon)
            Text(label)
        }
        .font(.caption)
        .foregroundColor(trendColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(trendColor.opacity(0.15))
        .cornerRadius(12)
    }

    private var trendColor: Color {
        switch direction {
        case .improving: return .green
        case .stable: return .secondary
        case .declining: return .orange
        }
    }
}

// MARK: - Change Indicator

struct ChangeIndicator: View {
    let change: Double
    let unit: String
    let higherIsBetter: Bool

    private var isPositive: Bool {
        higherIsBetter ? change > 0 : change < 0
    }

    private var displayChange: Double {
        abs(change)
    }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                .font(.caption2)

            Text(String(format: "%.1f", displayChange))
                .font(.caption)

            if !unit.isEmpty {
                Text(unit)
                    .font(.caption2)
            }
        }
        .foregroundColor(isPositive ? .green : .orange)
    }
}

#Preview {
    VStack(spacing: 24) {
        // Trend Indicators
        HStack(spacing: 16) {
            TrendIndicator(direction: .improving)
            TrendIndicator(direction: .stable)
            TrendIndicator(direction: .declining)
        }

        // Compact
        HStack(spacing: 16) {
            TrendIndicator(direction: .improving, compact: true)
            TrendIndicator(direction: .stable, compact: true)
            TrendIndicator(direction: .declining, compact: true)
        }

        // Trend Arrows
        HStack(spacing: 16) {
            TrendArrow(direction: .improving)
            TrendArrow(direction: .stable)
            TrendArrow(direction: .declining)
        }

        // Trend Badges
        VStack(spacing: 8) {
            TrendBadge(direction: .improving, label: "HRV trending up")
            TrendBadge(direction: .stable, label: "RHR stable")
            TrendBadge(direction: .declining, label: "Sleep declining")
        }

        // Change Indicators
        HStack(spacing: 16) {
            ChangeIndicator(change: 5.2, unit: "ms", higherIsBetter: true)
            ChangeIndicator(change: -3.1, unit: "bpm", higherIsBetter: false)
            ChangeIndicator(change: -2.5, unit: "ms", higherIsBetter: true)
        }
    }
    .padding()
}
