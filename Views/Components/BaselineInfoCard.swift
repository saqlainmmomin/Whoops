import SwiftUI

/// Whoop-style baseline info card shown during initial baseline period
/// Displays progress toward 28-day baseline establishment
struct BaselineInfoCard: View {
    let daysCompleted: Int
    let totalDays: Int
    var onWatchVideo: (() -> Void)?

    private var progress: Double {
        Double(daysCompleted) / Double(totalDays)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with info icon
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.whoopTeal)

                Text("Your Personalized Baseline")
                    .font(Theme.Fonts.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.textPrimary)
            }

            // Description
            Text("Your baseline is being established. Continue wearing your device to see personalized insights.")
                .font(Theme.Fonts.caption)
                .foregroundColor(Theme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.Colors.tertiary)

                        // Progress
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.Colors.whoopTeal)
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 8)

                Text("\(daysCompleted)/\(totalDays) days")
                    .font(Theme.Fonts.footnote)
                    .foregroundColor(Theme.Colors.textTertiary)
            }

            // Watch video link
            if onWatchVideo != nil {
                Button(action: { onWatchVideo?() }) {
                    HStack(spacing: 4) {
                        Text("WATCH THE VIDEO")
                            .font(Theme.Fonts.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.Colors.whoopTeal)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Theme.Colors.whoopTeal)
                    }
                }
            }
        }
        .padding(Theme.Dimensions.cardPadding)
        .whoopInfoCard()
    }
}

#Preview {
    VStack(spacing: 16) {
        BaselineInfoCard(
            daysCompleted: 14,
            totalDays: 28,
            onWatchVideo: {}
        )

        BaselineInfoCard(
            daysCompleted: 5,
            totalDays: 28
        )
    }
    .padding()
    .background(Theme.Colors.primary)
}
