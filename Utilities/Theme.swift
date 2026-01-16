import SwiftUI

// MARK: - Brutalist Design System
// Stark. Industrial. Raw.

struct Theme {

    // MARK: - Spacing System (8pt Grid)
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Border Weights
    enum Border {
        static let thin: CGFloat = 1
        static let medium: CGFloat = 2
        static let heavy: CGFloat = 4
    }

    // MARK: - Colors (Brutalist Palette)
    struct Colors {
        // Primary - Stark black/white
        static let void = Color.black                    // Primary background
        static let concrete = Color(hex: "0A0A0A")       // Secondary surface
        static let steel = Color(hex: "1A1A1A")          // Tertiary/inactive
        static let graphite = Color(hex: "2A2A2A")       // Borders/dividers

        // Text
        static let bone = Color.white                    // Primary text
        static let chalk = Color(hex: "888888")          // Secondary text
        static let ash = Color(hex: "555555")            // Disabled/inactive

        // THE accent - Industrial Rust Red
        static let rust = Color(hex: "FF2D00")           // Critical/active accent
        static let ember = Color(hex: "CC2400")          // Darker rust variant

        // MARK: - Score-Based Colors (Brutalist)
        // Only two states: normal (bone) or critical (rust)

        /// Recovery: rust when poor (0-33), bone otherwise
        static func recovery(score: Int) -> Color {
            score <= 33 ? rust : bone
        }

        /// Strain: rust when high (67+), bone otherwise
        static func strain(score: Int) -> Color {
            score >= 67 ? rust : bone
        }

        /// Universal status color - binary: critical or not
        static func status(isCritical: Bool) -> Color {
            isCritical ? rust : bone
        }

        // Legacy compatibility (maps to new system)
        static let sovereignBlack = void
        static let sovereignDarkGray = concrete
        static let panelGray = steel
        static let textWhite = bone
        static let textGray = chalk
        static let neonRed = rust
        static let neonTeal = bone
        static let neonGreen = bone
        static let neonGold = chalk
        static let neonBlue = chalk
    }

    // MARK: - Typography (Industrial)
    struct Fonts {
        /// Monospace bold - for all numeric values
        static func mono(size: CGFloat) -> Font {
            .system(size: size, weight: .bold, design: .monospaced)
        }

        /// Heavy display - massive numbers
        static func display(size: CGFloat) -> Font {
            .system(size: size, weight: .heavy, design: .monospaced)
        }

        /// Industrial headers - uppercase tracking
        static func header(size: CGFloat) -> Font {
            .system(size: size, weight: .bold, design: .default)
        }

        /// Labels - medium weight
        static func label(size: CGFloat) -> Font {
            .system(size: size, weight: .medium, design: .default)
        }

        /// Raw body text
        static func body(size: CGFloat) -> Font {
            .system(size: size, weight: .regular, design: .default)
        }

        // Legacy compatibility
        static func tensor(size: CGFloat) -> Font {
            mono(size: size)
        }
    }

    // MARK: - No Gradients in Brutalism
    // Flat colors only. Gradients are soft.
    struct Gradients {
        // These return flat colors disguised as gradients for compatibility
        static let recovery = LinearGradient(
            colors: [Colors.bone, Colors.bone],
            startPoint: .leading,
            endPoint: .trailing
        )

        static let strain = LinearGradient(
            colors: [Colors.bone, Colors.bone],
            startPoint: .leading,
            endPoint: .trailing
        )

        static func recovery(score: Int) -> LinearGradient {
            let color = Colors.recovery(score: score)
            return LinearGradient(colors: [color, color], startPoint: .leading, endPoint: .trailing)
        }

        static func strain(score: Int) -> LinearGradient {
            let color = Colors.strain(score: score)
            return LinearGradient(colors: [color, color], startPoint: .leading, endPoint: .trailing)
        }
    }
}

// MARK: - View Modifiers (Brutalist)

extension View {
    /// Hard-edged border, no rounded corners
    func brutalistBorder(_ color: Color = Theme.Colors.graphite, width: CGFloat = Theme.Border.thin) -> some View {
        self.overlay(
            Rectangle()
                .stroke(color, lineWidth: width)
        )
    }

    /// Industrial card style
    func brutalistCard() -> some View {
        self
            .background(Theme.Colors.concrete)
            .brutalistBorder()
    }

    /// Uppercase with wide tracking
    func industrialText() -> some View {
        self.textCase(.uppercase)
    }
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
