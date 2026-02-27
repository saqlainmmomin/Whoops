import SwiftUI

/// Whoop-style dual gauge hero for Overview tab
/// Clean layout: Recovery outer ring with strain value positioned clearly
/// No overlapping labels — metrics arranged around the ring with safe spacing
struct DualGaugeHero: View {
    let recoveryScore: Int
    let strainScore: Double
    let hrvValue: String
    let sleepPerformance: String

    // Per DESIGN_SPEC §3.1: Hero gauge = 200pt diameter
    private let ringDiameter: CGFloat = 180
    private let ringStrokeWidth: CGFloat = 12

    /// Recovery progress (0-1)
    private var recoveryProgress: Double {
        Double(recoveryScore) / 100.0
    }

    /// Strain progress (0-21 scale normalized to 0-1)
    private var strainProgress: Double {
        min(strainScore / 21.0, 1.0)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Recovery + Strain labels row (ABOVE the ring — no overlap)
            HStack {
                // Recovery value (left-aligned)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("\(recoveryScore)")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(recoveryColor)
                        Text("%")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(recoveryColor)
                    }
                    Text("RECOVERY")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(recoveryColor)
                        .tracking(1.2)
                }

                Spacer()

                // Strain value (right-aligned)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f", strainScore))
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(Theme.Colors.whoopCyan)
                    Text("STRAIN")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.Colors.whoopCyan)
                        .tracking(1.2)
                }
            }
            .padding(.horizontal, 30)

            // Main ring — single ZStack, no label overlaps
            ZStack {
                // Background track (270° arc)
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(
                        Theme.Colors.tertiary,
                        style: StrokeStyle(lineWidth: ringStrokeWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))

                // Recovery progress arc (yellow → orange)
                Circle()
                    .trim(from: 0, to: recoveryProgress * 0.75)
                    .stroke(
                        AngularGradient(
                            colors: [Theme.Colors.whoopYellow, Theme.Colors.whoopOrange],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(270 * recoveryProgress)
                        ),
                        style: StrokeStyle(
                            lineWidth: ringStrokeWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(135))

                // Center: W logo only
                Text("W")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            .frame(width: ringDiameter, height: ringDiameter)

            // HRV and Sleep below the ring
            HStack(spacing: 40) {
                // HRV
                VStack(spacing: 2) {
                    Text(hrvValue.replacingOccurrences(of: "ms", with: ""))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    Text("HRV")
                        .font(Theme.Fonts.footnote)
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                // Divider
                Rectangle()
                    .fill(Theme.Colors.borderSubtle)
                    .frame(width: 1, height: 24)

                // Sleep Performance
                VStack(spacing: 2) {
                    Text(sleepPerformance.replacingOccurrences(of: "%", with: ""))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    Text("SLEEP %")
                        .font(Theme.Fonts.footnote)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
        }
        .padding(.vertical, 16)
    }

    /// Recovery color based on score (green/yellow/red zones)
    private var recoveryColor: Color {
        switch recoveryScore {
        case 67...100:
            return Theme.Colors.whoopTeal
        case 34..<67:
            return Theme.Colors.whoopYellow
        default:
            return Color(hex: "#FF3B30")
        }
    }
}

#Preview {
    VStack {
        DualGaugeHero(
            recoveryScore: 51,
            strainScore: 11.3,
            hrvValue: "57ms",
            sleepPerformance: "--"
        )

        DualGaugeHero(
            recoveryScore: 85,
            strainScore: 4.2,
            hrvValue: "42ms",
            sleepPerformance: "85%"
        )
    }
    .padding()
    .background(Theme.Colors.primary)
}
