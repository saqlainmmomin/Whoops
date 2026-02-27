import SwiftUI

/// WHOOP-style "What is X?" info card with gradient border and description
/// Matches WHOOP design: Title, description text, chevron, gradient teal/purple border
struct WhatIsInfoCard: View {
    let title: String
    var description: String? = nil
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)

                    if let description = description {
                        Text(description)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(16)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Dimensions.cardCornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Theme.Colors.whoopTeal.opacity(0.6),
                                Color(hex: "#9F44D3").opacity(0.4)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(WhoopCardButtonStyle())
    }
}

/// Extended info card with image (for What is Recovery/Sleep/Strain with thumbnail)
struct WhatIsInfoCardWithImage: View {
    let title: String
    let description: String
    var imageName: String? = nil
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text(description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                // Image placeholder (if no actual image, show gradient placeholder)
                if imageName != nil {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.cardBackgroundAlt, Theme.Colors.tertiary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 60)
                        .overlay(
                            VStack(spacing: 2) {
                                Text("77%")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Theme.Colors.whoopTeal)
                                Text("9:52")
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.Colors.textTertiary)
                            }
                        )
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(16)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Dimensions.cardCornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Theme.Colors.whoopTeal.opacity(0.6),
                                Color(hex: "#9F44D3").opacity(0.4)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(WhoopCardButtonStyle())
    }
}

/// Button style for card interactions
struct WhoopCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        WhatIsInfoCard(
            title: "What is Recovery?",
            description: "Discover the science behind Recovery and how it measures health and fitness."
        )

        WhatIsInfoCardWithImage(
            title: "What is Sleep Performance?",
            description: "Discover the science behind good sleep, how it's measured, and how it achieves it.",
            imageName: "sleep_preview"
        )

        WhatIsInfoCard(
            title: "What is Strain?"
        )
    }
    .padding()
    .background(Theme.Colors.primary)
}
