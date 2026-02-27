import SwiftUI

/// Whoop-style dashed circular gauge for Sleep Performance
/// Features dashed border and SHARE button
struct DashedGauge: View {
    let value: Int
    let label: String
    var onShare: (() -> Void)?
    var onInfo: (() -> Void)?

    private let diameter: CGFloat = 180

    private var progress: Double {
        Double(value) / 100.0
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background dashed circle
                Circle()
                    .stroke(
                        Theme.Colors.tertiary,
                        style: StrokeStyle(
                            lineWidth: Theme.Dimensions.dashedGaugeStrokeWidth,
                            dash: [8, 8]
                        )
                    )

                // Progress arc (solid)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Theme.Colors.whoopTeal,
                        style: StrokeStyle(
                            lineWidth: Theme.Dimensions.gaugeStrokeWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))

                // Center content
                VStack(spacing: 4) {
                    Text("\(value)%")
                        .font(Theme.Fonts.hero)
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text(label.uppercased())
                        .font(Theme.Fonts.sectionHeader)
                        .tracking(1)
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                // Info button (top-right)
                if onInfo != nil {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { onInfo?() }) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
            .frame(width: diameter, height: diameter)

            // Share button
            if onShare != nil {
                Button(action: { onShare?() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                        Text("SHARE")
                            .font(Theme.Fonts.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Theme.Colors.whoopTeal)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.Colors.cardBackground)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(Theme.Colors.whoopTeal.opacity(0.5), lineWidth: 1)
                    )
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        DashedGauge(
            value: 66,
            label: "Sleep Performance",
            onShare: {},
            onInfo: {}
        )

        DashedGauge(
            value: 85,
            label: "Sleep Performance",
            onShare: {}
        )
    }
    .padding()
    .background(Theme.Colors.primary)
}
