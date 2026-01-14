import SwiftUI

struct DeepDataCard<Content: View>: View {
    let title: String
    let value: String
    let subtitle: String?
    let accent: Color
    let trend: TrendDirection?
    @ViewBuilder let content: Content

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        accent: Color = Theme.Colors.neonTeal,
        trend: TrendDirection? = nil,
        @ViewBuilder content: () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.accent = accent
        self.trend = trend
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(title.uppercased())
                    .font(Theme.Fonts.label(size: 12))
                    .foregroundColor(Theme.Colors.textGray)
                    .tracking(1)

                Spacer()

                // Trend indicator
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(trendColor(trend))
                }

                // Tensor-like decorative element
                Capsule()
                    .fill(accent)
                    .frame(width: 4, height: 4)
            }

            // Main Value
            HStack(alignment: .lastTextBaseline) {
                Text(value)
                    .font(Theme.Fonts.tensor(size: 28))
                    .foregroundColor(.white)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Theme.Fonts.label(size: 14))
                        .foregroundColor(Theme.Colors.textGray)
                }

                Spacer()

                // Chevron for navigation hint
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.textGray.opacity(0.5))
            }

            // Custom Visual Content (Graph/Sparkline)
            content
        }
        .padding(16)
        .background(Theme.Colors.panelGray)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    private func trendColor(_ trend: TrendDirection) -> Color {
        switch trend {
        case .improving: return Theme.Colors.neonGreen
        case .stable: return Theme.Colors.textGray
        case .declining: return Theme.Colors.neonRed
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        DeepDataCard(
            title: "Heart Rate Variability",
            value: "42 ms",
            accent: Theme.Colors.neonTeal
        )
    }
    .padding()
}
