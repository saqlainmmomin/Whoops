import SwiftUI

/// Error banner for displaying warnings and alerts
/// Shows at top of screen with dismiss action
struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Theme.Colors.caution)

            Text(message)
                .font(Theme.Fonts.body)
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        .padding(Theme.Spacing.cardGap)
        .background(Theme.Colors.secondary)
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundColor(Theme.Colors.caution),
            alignment: .top
        )
    }
}

// MARK: - Error Banner Variants

/// Critical error banner (red accent)
struct CriticalErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(Theme.Colors.critical)

            Text(message)
                .font(Theme.Fonts.body)
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        .padding(Theme.Spacing.cardGap)
        .background(Theme.Colors.secondary)
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundColor(Theme.Colors.critical),
            alignment: .top
        )
    }
}

/// Info banner (blue accent)
struct InfoBanner: View {
    let message: String
    let onDismiss: (() -> Void)?

    init(message: String, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundColor(Theme.Colors.neutral)

            Text(message)
                .font(Theme.Fonts.body)
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
        }
        .padding(Theme.Spacing.cardGap)
        .background(Theme.Colors.secondary)
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundColor(Theme.Colors.neutral),
            alignment: .top
        )
    }
}

/// Success banner (green accent)
struct SuccessBanner: View {
    let message: String
    let autoDismissAfter: TimeInterval?
    let onDismiss: () -> Void

    init(message: String, autoDismissAfter: TimeInterval? = 3.0, onDismiss: @escaping () -> Void) {
        self.message = message
        self.autoDismissAfter = autoDismissAfter
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Theme.Colors.optimal)

            Text(message)
                .font(Theme.Fonts.body)
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        .padding(Theme.Spacing.cardGap)
        .background(Theme.Colors.secondary)
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundColor(Theme.Colors.optimal),
            alignment: .top
        )
        .onAppear {
            if let delay = autoDismissAfter {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    onDismiss()
                }
            }
        }
    }
}

// MARK: - Banner Container

/// View modifier for showing banners
struct BannerModifier: ViewModifier {
    @Binding var isPresented: Bool
    let banner: AnyView

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if isPresented {
                banner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

extension View {
    func errorBanner(
        isPresented: Binding<Bool>,
        message: String,
        onDismiss: @escaping () -> Void
    ) -> some View {
        modifier(BannerModifier(
            isPresented: isPresented,
            banner: AnyView(ErrorBanner(message: message, onDismiss: {
                onDismiss()
                isPresented.wrappedValue = false
            }))
        ))
    }

    func successBanner(
        isPresented: Binding<Bool>,
        message: String
    ) -> some View {
        modifier(BannerModifier(
            isPresented: isPresented,
            banner: AnyView(SuccessBanner(message: message, onDismiss: {
                isPresented.wrappedValue = false
            }))
        ))
    }
}

// MARK: - Preview

#Preview("Banners") {
    VStack(spacing: 16) {
        ErrorBanner(message: "Sensor data anomaly detected", onDismiss: { })
        CriticalErrorBanner(message: "Health data sync failed", onDismiss: { })
        InfoBanner(message: "Syncing health data...", onDismiss: { })
        SuccessBanner(message: "Data synced successfully", autoDismissAfter: nil, onDismiss: { })
    }
    .padding()
    .background(Theme.Colors.primary)
}
