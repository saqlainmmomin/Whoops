import SwiftUI

// MARK: - Brutalist Meter
// Industrial horizontal bar meter. No circles. No softness.

struct SovereignGauge: View {
    let score: Int
    let type: GaugeType
    var size: CGFloat = 200  // Height reference, width fills container

    enum GaugeType {
        case recovery
        case strain

        var label: String {
            switch self {
            case .recovery: return "RECOVERY"
            case .strain: return "STRAIN"
            }
        }

        var statusText: (Int) -> String {
            switch self {
            case .recovery:
                return { score in
                    switch score {
                    case 0...33: return "CRITICAL"
                    case 34...66: return "MODERATE"
                    default: return "OPTIMAL"
                    }
                }
            case .strain:
                return { score in
                    switch score {
                    case 0...33: return "LOW"
                    case 34...66: return "MODERATE"
                    default: return "HIGH"
                    }
                }
            }
        }

        var max: Double { 100 }
    }

    private var scoreColor: Color {
        switch type {
        case .recovery: return Theme.Colors.recovery(score: score)
        case .strain: return Theme.Colors.strain(score: score)
        }
    }

    private var isCritical: Bool {
        switch type {
        case .recovery: return score <= 33
        case .strain: return score >= 67
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Label row
            HStack {
                Text(type.label)
                    .font(Theme.Fonts.label(size: 12))
                    .foregroundColor(Theme.Colors.chalk)
                    .tracking(3)

                Spacer()

                Text(type.statusText(score))
                    .font(Theme.Fonts.mono(size: 11))
                    .foregroundColor(isCritical ? Theme.Colors.rust : Theme.Colors.chalk)
                    .tracking(2)
            }

            // Main meter row
            HStack(alignment: .center, spacing: Theme.Spacing.md) {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Track (inactive)
                        Rectangle()
                            .fill(Theme.Colors.steel)
                            .frame(height: size * 0.15)

                        // Fill (active)
                        Rectangle()
                            .fill(scoreColor)
                            .frame(width: geo.size.width * CGFloat(score) / 100, height: size * 0.15)

                        // Tick marks every 25%
                        HStack(spacing: 0) {
                            ForEach(0..<4, id: \.self) { i in
                                Rectangle()
                                    .fill(Theme.Colors.void)
                                    .frame(width: 2, height: size * 0.15)
                                if i < 3 {
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .frame(height: size * 0.15)

                // Score display
                Text("\(score)")
                    .font(Theme.Fonts.display(size: size * 0.35))
                    .foregroundColor(scoreColor)
                    .frame(minWidth: size * 0.5, alignment: .trailing)
                    .monospacedDigit()
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.concrete)
        .brutalistBorder(isCritical ? Theme.Colors.rust : Theme.Colors.graphite)
    }
}

// MARK: - Compact Variant for Secondary Display

struct BrutalistMeterCompact: View {
    let score: Int
    let label: String
    var isCritical: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(label)
                .font(Theme.Fonts.label(size: 10))
                .foregroundColor(Theme.Colors.chalk)
                .tracking(2)

            HStack(spacing: Theme.Spacing.sm) {
                // Mini bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Theme.Colors.steel)

                        Rectangle()
                            .fill(isCritical ? Theme.Colors.rust : Theme.Colors.bone)
                            .frame(width: geo.size.width * CGFloat(score) / 100)
                    }
                }
                .frame(height: 8)

                Text("\(score)")
                    .font(Theme.Fonts.mono(size: 16))
                    .foregroundColor(isCritical ? Theme.Colors.rust : Theme.Colors.bone)
                    .monospacedDigit()
            }
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.concrete)
        .brutalistBorder()
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.Colors.void.ignoresSafeArea()

        VStack(spacing: Theme.Spacing.lg) {
            // Recovery examples
            SovereignGauge(score: 25, type: .recovery, size: 60)
            SovereignGauge(score: 78, type: .recovery, size: 60)

            Divider().background(Theme.Colors.graphite)

            // Strain examples
            SovereignGauge(score: 45, type: .strain, size: 60)
            SovereignGauge(score: 85, type: .strain, size: 60)

            Divider().background(Theme.Colors.graphite)

            // Compact variants
            HStack(spacing: Theme.Spacing.sm) {
                BrutalistMeterCompact(score: 42, label: "HRV")
                BrutalistMeterCompact(score: 85, label: "STRAIN", isCritical: true)
            }
        }
        .padding()
    }
}
