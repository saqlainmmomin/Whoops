import SwiftUI

/// Modifier that respects Reduce Motion accessibility setting
struct ReduceMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? nil : .default, value: UUID())
    }
}

extension View {
    /// Apply this modifier to respect Reduce Motion accessibility setting
    func respectReduceMotion() -> some View {
        modifier(ReduceMotionModifier())
    }
}

// MARK: - Conditional Animation Modifier

struct ConditionalAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let value: V
    let animation: Animation

    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? nil : animation, value: value)
    }
}

extension View {
    /// Apply animation that respects Reduce Motion setting
    func animationIfEnabled<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(ConditionalAnimationModifier(value: value, animation: animation))
    }
}

// MARK: - Accessibility Labels

extension View {
    /// Add accessibility label for metric gauges
    func accessibilityMetricGauge(
        metric: String,
        value: Int,
        category: String? = nil,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel("\(metric): \(value) percent" + (category.map { ", \($0)" } ?? ""))
            .accessibilityHint(hint ?? "Double tap for \(metric.lowercased()) details")
    }

    /// Add accessibility label for strain gauge (0-21 scale)
    func accessibilityStrainGauge(
        value: Double,
        target: Double
    ) -> some View {
        let status = value >= target ? "target reached" : "below target"
        return self
            .accessibilityLabel("Strain: \(String(format: "%.1f", value)) of \(String(format: "%.1f", target)), \(status)")
            .accessibilityHint("Double tap for strain details")
    }

    /// Add accessibility for sleep metrics
    func accessibilitySleepMetric(
        hours: Double,
        performance: Int
    ) -> some View {
        let hoursInt = Int(hours)
        let minutes = Int((hours - Double(hoursInt)) * 60)
        return self
            .accessibilityLabel("Sleep: \(hoursInt) hours \(minutes) minutes, \(performance) percent performance")
            .accessibilityHint("Double tap for sleep details")
    }
}

// MARK: - Large Content Viewer

struct LargeContentViewerModifier: ViewModifier {
    let text: String
    let image: String?

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .accessibilityShowsLargeContentViewer {
                    VStack {
                        if let image = image {
                            Image(systemName: image)
                                .font(.largeTitle)
                        }
                        Text(text)
                            .font(.largeTitle)
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    /// Show large content viewer for accessibility
    func largeContentViewer(text: String, image: String? = nil) -> some View {
        modifier(LargeContentViewerModifier(text: text, image: image))
    }
}

// MARK: - High Contrast Mode

struct HighContrastModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) var contrast

    let normalOpacity: Double
    let highContrastOpacity: Double

    func body(content: Content) -> some View {
        content
            .opacity(contrast == .increased ? highContrastOpacity : normalOpacity)
    }
}

extension View {
    /// Adjust opacity based on high contrast mode
    func contrastAwareOpacity(normal: Double = 0.6, highContrast: Double = 1.0) -> some View {
        modifier(HighContrastModifier(normalOpacity: normal, highContrastOpacity: highContrast))
    }
}

// MARK: - Focus State for tvOS/macOS

struct FocusableCardModifier: ViewModifier {
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .focusable()
            .focused($isFocused)
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

extension View {
    /// Make a card focusable with scale feedback
    func focusableCard() -> some View {
        modifier(FocusableCardModifier())
    }
}
