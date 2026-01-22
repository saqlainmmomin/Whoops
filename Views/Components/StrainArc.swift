import SwiftUI

struct StrainArc: View {
    let score: Double  // 0-21 scale
    var targetStrain: Double? = nil
    var weeklyAverage: Double? = nil
    var onStartActivity: (() -> Void)? = nil

    private let maxStrain: Double = 21
    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                // Background arc (270 degrees)
                Circle()
                    .trim(from: 0.125, to: 0.875)
                    .stroke(Theme.Colors.borderSubtle, lineWidth: 12)
                    .rotationEffect(.degrees(90))

                // Progress arc with gradient
                Circle()
                    .trim(from: 0.125, to: 0.125 + (0.75 * animatedProgress))
                    .stroke(
                        Theme.Gradients.strain(progress: score / maxStrain),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))

                // Score display
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", score))
                        .font(Theme.Fonts.display(48))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("STRAIN")
                        .font(Theme.Fonts.label(10))
                        .foregroundStyle(Theme.Colors.strainColor(for: score))
                        .tracking(2)

                    if let target = targetStrain {
                        Text("TARGET: \(String(format: "%.1f", target))")
                            .font(Theme.Fonts.mono(10))
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .padding(.top, 4)
                    }
                }
            }
            .frame(width: 160, height: 160)
            .strainGlow(for: score)

            if let action = onStartActivity {
                Button(action: action) {
                    Text("START ACTIVITY")
                        .font(Theme.Fonts.label(11))
                        .tracking(1)
                        .foregroundStyle(Theme.Colors.strainColor(for: score))
                }
            }

            if let avg = weeklyAverage {
                Text("7D AVG: \(String(format: "%.1f", avg))")
                    .font(Theme.Fonts.mono(11))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = score / maxStrain
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProgress = newValue / maxStrain
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        StrainArc(score: 5.2, targetStrain: 8.0, weeklyAverage: 6.5)
        StrainArc(score: 12.4, targetStrain: 14.0, weeklyAverage: 11.2)
        StrainArc(score: 18.7, targetStrain: 16.0, weeklyAverage: 15.3) {
            print("Start activity")
        }
    }
    .preferredColorScheme(.dark)
    .padding()
    .background(Theme.Colors.void)
}
