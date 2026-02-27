import SwiftUI

/// Whoop-style dual gauge hero for Overview tab
/// Single ring with W logo center, metrics positioned around ring
struct DualGaugeHero: View {
    let recoveryScore: Int
    let strainScore: Double
    let hrvValue: String
    let sleepPerformance: String

    private let ringDiameter: CGFloat = 140
    private let ringStrokeWidth: CGFloat = 10

    /// Recovery progress (0-1)
    private var recoveryProgress: Double {
        Double(recoveryScore) / 100.0
    }

    /// Strain progress (0-21 scale normalized to 0-1)
    private var strainProgress: Double {
        min(strainScore / 21.0, 1.0)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Main content row: Recovery - Ring - Strain
            HStack(alignment: .center, spacing: 0) {
                // LEFT: Recovery metrics
                VStack(alignment: .center, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("\(recoveryScore)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(Theme.Colors.whoopYellow)
                        Text("%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.whoopYellow)
                    }

                    Text("RECOVERY")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.Colors.whoopYellow)
                        .tracking(1)

                    // HRV below
                    VStack(spacing: 2) {
                        Text(hrvValue.replacingOccurrences(of: "ms", with: ""))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)

                        Text("HRV")
                            .font(Theme.Fonts.footnote)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .padding(.top, 8)
                }
                .frame(width: 80)

                // CENTER: Ring with W logo
                ZStack {
                    // Background track (gray)
                    Circle()
                        .stroke(
                            Theme.Colors.tertiary,
                            lineWidth: ringStrokeWidth
                        )

                    // Recovery arc (yellow) - starts from top, goes clockwise
                    Circle()
                        .trim(from: 0, to: recoveryProgress)
                        .stroke(
                            Theme.Colors.whoopYellow,
                            style: StrokeStyle(
                                lineWidth: ringStrokeWidth,
                                lineCap: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))

                    // W logo in center
                    Text("W")
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                .frame(width: ringDiameter, height: ringDiameter)

                // RIGHT: Strain metrics
                VStack(alignment: .center, spacing: 4) {
                    Text(String(format: "%.1f", strainScore))
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(Theme.Colors.whoopCyan)

                    Text("STRAIN")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.Colors.whoopCyan)
                        .tracking(1)

                    // Sleep % below
                    VStack(spacing: 2) {
                        Text(sleepPerformance.replacingOccurrences(of: "%", with: ""))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)

                        Text("SLEEP")
                            .font(Theme.Fonts.footnote)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .padding(.top, 8)
                }
                .frame(width: 80)
            }
        }
        .padding(.vertical, 16)
    }
}

#Preview {
    VStack {
        DualGaugeHero(
            recoveryScore: 58,
            strainScore: 4.9,
            hrvValue: "40ms",
            sleepPerformance: "73%"
        )
    }
    .padding()
    .background(Theme.Colors.primary)
}
