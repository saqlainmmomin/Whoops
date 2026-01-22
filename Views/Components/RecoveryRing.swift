import SwiftUI

struct RecoveryRing: View {
    let score: Double
    let category: String
    var weeklyAverage: Double? = nil
    var showAnimation: Bool = true

    @State private var animatedScore: Double = 0

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Theme.Colors.borderSubtle, lineWidth: 14)

                // Progress ring with gradient
                Circle()
                    .trim(from: 0, to: animatedScore / 100)
                    .stroke(
                        Theme.Gradients.recovery(for: score),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Inner glow
                Circle()
                    .fill(Theme.Colors.recoveryColor(for: score).opacity(0.15))
                    .blur(radius: 30)
                    .scaleEffect(0.6)

                // Score display
                VStack(spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(score))")
                            .font(Theme.Fonts.display(72))
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text("%")
                            .font(Theme.Fonts.mono(24))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .offset(y: -20)
                    }

                    Text(category.uppercased())
                        .font(Theme.Fonts.label(12))
                        .foregroundStyle(Theme.Colors.recoveryColor(for: score))
                        .tracking(2)
                }
            }
            .frame(width: 220, height: 220)
            .recoveryGlow(for: score)

            if let avg = weeklyAverage {
                Text("7D AVG: \(Int(avg))%")
                    .font(Theme.Fonts.mono(12))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .onAppear {
            if showAnimation {
                withAnimation(.easeOut(duration: 1.2)) {
                    animatedScore = score
                }
            } else {
                animatedScore = score
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.easeOut(duration: 0.8)) {
                animatedScore = newValue
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        RecoveryRing(score: 92, category: "Peak", weeklyAverage: 85)
        RecoveryRing(score: 72, category: "Good", weeklyAverage: 68)
        RecoveryRing(score: 45, category: "Moderate", weeklyAverage: 52)
        RecoveryRing(score: 25, category: "Low", weeklyAverage: 30)
    }
    .preferredColorScheme(.dark)
    .padding()
    .background(Theme.Colors.void)
}
