import SwiftUI

// MARK: - Session 7: Whoop-Aligned Design System
// Semantic colors tied to physiological states
// Single-color states, no competing gradients

struct Theme {

    // MARK: - Semantic Color System (Session 7)
    struct Colors {
        // Backgrounds (OLED black for battery efficiency)
        static let primary = Color(hex: "#000000")       // OLED black
        static let secondary = Color(hex: "#0A0A0A")     // Cards
        static let tertiary = Color(hex: "#1C1C1E")      // Elevated surfaces

        // MARK: - Whoop Design System Colors (Pixel-Perfect)
        static let whoopYellow = Color(hex: "#FFD700")      // Recovery ring
        static let whoopOrange = Color(hex: "#FFA500")      // Recovery ring gradient end
        static let whoopCyan = Color(hex: "#00BFFF")        // Strain ring
        static let whoopCyanDark = Color(hex: "#0099CC")    // Strain ring gradient end
        static let whoopTeal = Color(hex: "#00D4AA")        // Sleep accent, links, positive trends
        static let cardBackground = Color(hex: "#1C1C1E")   // Card backgrounds
        static let cardBackgroundAlt = Color(hex: "#2C2C2E") // Info cards, lighter variant
        static let linkColor = Color(hex: "#00D4AA")        // CTAs, links

        // Sleep Stage Colors
        static let stageAwake = Color(hex: "#636366")
        static let stageLight = Color(hex: "#5B9BD5")
        static let stageDeep = Color(hex: "#7B68EE")
        static let stageREM = Color(hex: "#BA68C8")

        // Legacy background names (backward compatibility)
        static let void = Color(hex: "#000000")
        static let surface = Color(hex: "#0A0A0B")
        static let surfaceElevated = Color(hex: "#141416")
        static let surfaceCard = Color(hex: "#1C1C1F")

        // Text Hierarchy
        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "#A0A0A0")
        static let textTertiary = Color(hex: "#666666")

        // Borders
        static let borderSubtle = Color(hex: "#27272A")
        static let borderMedium = Color(hex: "#3F3F46")

        // MARK: - Semantic Colors (Physiological States)
        // NO YELLOW - redundant with orange
        // NO PURPLE GLOW EFFECTS

        /// Green: >80% sleep, HRV up, recovery 70-100
        static let optimal = Color(hex: "#00FF41")

        /// Blue: informational, time-based
        static let neutral = Color(hex: "#4A9EFF")

        /// Orange: debt accumulating, HRV below baseline
        static let caution = Color(hex: "#FF9500")

        /// Red: <60% sleep, high stress
        static let critical = Color(hex: "#FF3B30")

        // Legacy Recovery States (backward compatibility)
        static let recoveryPeak = Color(hex: "#00D26A")
        static let recoveryGood = Color(hex: "#7DD956")
        static let recoveryModerate = Color(hex: "#FFCC00")
        static let recoveryLow = Color(hex: "#FF6B35")
        static let recoveryCritical = Color(hex: "#FF3B30")

        // Legacy Strain States (backward compatibility)
        static let strainLight = Color(hex: "#4ECDC4")
        static let strainModerate = Color(hex: "#45B7D1")
        static let strainHigh = Color(hex: "#5A67D8")
        static let strainOverreach = Color(hex: "#9F44D3")

        // Legacy Biometrics (backward compatibility)
        static let hrvPositive = Color(hex: "#10B981")
        static let hrvNegative = Color(hex: "#EF4444")
        static let rhrPositive = Color(hex: "#14B8A6")
        static let rhrNegative = Color(hex: "#F97316")

        // Legacy Sleep (backward compatibility)
        static let sleepOptimal = Color(hex: "#6366F1")
        static let sleepSufficient = Color(hex: "#8B5CF6")
        static let sleepPoor = Color(hex: "#A78BFA")

        // MARK: - Session 7: Semantic Color Functions

        /// Recovery state color (semantic)
        static func recovery(score: Int) -> Color {
            switch score {
            case 70...100: return optimal
            case 34..<70: return caution
            default: return critical
            }
        }

        /// Strain state color based on current vs target
        static func strain(current: Double, target: Double) -> Color {
            let ratio = current / max(target, 0.1)
            if ratio < 0.5 { return neutral }       // Under target
            if ratio < 1.0 { return optimal }       // Approaching target
            if ratio < 1.2 { return caution }       // At/slightly over
            return critical                          // Overreach
        }

        /// HRV deviation color
        static func hrv(deviationPercent: Double) -> Color {
            if deviationPercent >= 10 { return optimal }    // 10%+ above baseline
            if deviationPercent >= -10 { return neutral }   // Within normal range
            if deviationPercent >= -20 { return caution }   // Below baseline
            return critical                                   // Significantly below
        }

        /// Sleep performance color
        static func sleepPerformance(score: Int) -> Color {
            switch score {
            case 80...100: return optimal
            case 60..<80: return neutral
            default: return critical
            }
        }

        // Utility Functions
        static func recoveryColor(for score: Double) -> Color {
            switch score {
            case 85...100: return recoveryPeak
            case 67..<85: return recoveryGood
            case 34..<67: return recoveryModerate
            case 1..<34: return recoveryLow
            default: return recoveryCritical
            }
        }

        static func strainColor(for score: Double) -> Color {
            switch score {
            case 0..<8: return strainLight
            case 8..<14: return strainModerate
            case 14..<18: return strainHigh
            default: return strainOverreach
            }
        }

        // Legacy compatibility (maps to new system)
        static let bone = textPrimary
        static let chalk = textSecondary
        static let ash = textTertiary
        static let concrete = surface
        static let steel = surfaceElevated
        static let graphite = borderSubtle
        static let rust = recoveryCritical
        static let ember = Color(hex: "#CC2400")

        static let sovereignBlack = void
        static let sovereignDarkGray = surface
        static let panelGray = surfaceElevated
        static let textWhite = textPrimary
        static let textGray = textSecondary
        static let neonRed = recoveryCritical
        static let neonTeal = strainLight
        static let neonGreen = recoveryPeak
        static let neonGold = recoveryModerate
        static let neonBlue = strainModerate

        /// Strain color for integer score (legacy compatibility)
        static func strain(score: Int) -> Color {
            strainColor(for: Double(score))
        }

        /// Legacy recovery color using gradient-style ranges
        static func recoveryLegacy(score: Int) -> Color {
            recoveryColor(for: Double(score))
        }

        /// Universal status color - binary: critical or not
        static func status(isCritical: Bool) -> Color {
            isCritical ? recoveryCritical : textPrimary
        }
    }

    // MARK: - Gradients
    struct Gradients {
        // MARK: - Whoop Pixel-Perfect Ring Gradients

        /// Recovery ring gradient (yellow to orange) - Whoop style
        static func recoveryRing(progress: Double) -> AngularGradient {
            AngularGradient(
                colors: [Colors.whoopYellow, Colors.whoopOrange],
                center: .center,
                startAngle: .degrees(135),
                endAngle: .degrees(135 + 270 * min(progress, 1.0))
            )
        }

        /// Strain ring gradient (cyan) - Whoop style
        static func strainRing(progress: Double) -> AngularGradient {
            AngularGradient(
                colors: [Colors.whoopCyan, Colors.whoopCyanDark],
                center: .center,
                startAngle: .degrees(135),
                endAngle: .degrees(135 + 270 * min(progress, 1.0))
            )
        }

        /// Info card gradient (teal fade)
        static let infoCard = LinearGradient(
            colors: [Color(hex: "#00D4AA").opacity(0.2), Color.clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Teal accent gradient for cards
        static let tealAccent = LinearGradient(
            colors: [Colors.whoopTeal.opacity(0.3), Colors.whoopTeal.opacity(0.1)],
            startPoint: .leading,
            endPoint: .trailing
        )

        static func recovery(for score: Double) -> LinearGradient {
            let colors: [Color] = switch score {
            case 85...100: [Color(hex: "#00D26A"), Color(hex: "#00F5A0"), Color(hex: "#00D9F5")]
            case 67..<85: [Color(hex: "#7DD956"), Color(hex: "#34D399"), Color(hex: "#10B981")]
            case 34..<67: [Color(hex: "#FCD34D"), Color(hex: "#FBBF24"), Color(hex: "#F59E0B")]
            case 1..<34: [Color(hex: "#FB923C"), Color(hex: "#F97316"), Color(hex: "#EA580C")]
            default: [Color(hex: "#F87171"), Color(hex: "#EF4444"), Color(hex: "#DC2626")]
            }
            return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        }

        static func strain(progress: Double) -> AngularGradient {
            AngularGradient(
                colors: [
                    Color(hex: "#4ECDC4"),
                    Color(hex: "#45B7D1"),
                    Color(hex: "#667EEA"),
                    Color(hex: "#9F44D3"),
                    Color(hex: "#F093FB")
                ],
                center: .center,
                startAngle: .degrees(135),
                endAngle: .degrees(135 + (270 * min(progress, 1.0)))
            )
        }

        static let cardDepth = LinearGradient(
            colors: [Color(hex: "#1C1C1F"), Color(hex: "#141416")],
            startPoint: .top,
            endPoint: .bottom
        )

        static let sleepAmbient = LinearGradient(
            colors: [
                Color(hex: "#1E1B4B").opacity(0.6),
                Color(hex: "#312E81").opacity(0.3),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        // Legacy compatibility
        static let recovery = LinearGradient(
            colors: [Colors.recoveryGood, Colors.recoveryPeak],
            startPoint: .leading,
            endPoint: .trailing
        )

        static let strain = LinearGradient(
            colors: [Colors.strainLight, Colors.strainHigh],
            startPoint: .leading,
            endPoint: .trailing
        )

        /// Legacy recovery gradient for integer score
        static func recovery(score: Int) -> LinearGradient {
            recovery(for: Double(score))
        }

        /// Legacy strain gradient for integer score
        static func strain(score: Int) -> LinearGradient {
            let color = Colors.strainColor(for: Double(score))
            return LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
        }
    }

    // MARK: - Typography (SF Pro)
    struct Fonts {
        /// Hero metrics (76%, 4.3, 108ms) - Sharp, condensed look
        static let heroMetric = Font.system(size: 72, weight: .heavy, design: .default)

        // MARK: - Whoop Typography Scale

        /// Hero value - 72pt Heavy (main percentages: 58%, 66%) - More impactful than bold
        static let hero = Font.system(size: 72, weight: .heavy, design: .default)

        /// Hero number - Specialized for large display numbers with tighter tracking
        static let heroNumber = Font.system(size: 64, weight: .black, design: .monospaced)

        /// Large value - 48pt Bold (strain values: 12.8)
        static let largeValue = Font.system(size: 48, weight: .bold, design: .default)

        /// Medium value - 28pt Semibold (metric tile values)
        static let mediumValue = Font.system(size: 28, weight: .semibold, design: .default)

        /// Small value - 20pt Medium (stats row values)
        static let smallValue = Font.system(size: 20, weight: .medium, design: .default)

        /// Section header - 13pt Semibold (UPPERCASE headers)
        static let sectionHeader = Font.system(size: 13, weight: .semibold, design: .default)

        /// Tab label - 13pt Medium
        static let tabLabel = Font.system(size: 13, weight: .medium, design: .default)

        /// Caption - 13pt Regular
        static let caption = Font.system(size: 13, weight: .regular, design: .default)

        /// Footnote - 11pt Regular (baseline comparisons)
        static let footnote = Font.system(size: 11, weight: .regular, design: .default)

        /// Body text
        static let body = Font.system(size: 17, weight: .regular, design: .default)

        /// Display numerals (SF Pro Display)
        static func display(_ size: CGFloat) -> Font {
            .system(size: size, weight: .bold, design: .default)
        }

        /// Labels with tracking (RECOVERY, STRAIN, OVERVIEW)
        static func label(_ size: CGFloat) -> Font {
            .system(size: size, weight: .semibold, design: .default)
        }

        // Legacy compatibility
        static func mono(_ size: CGFloat) -> Font {
            .system(size: size, weight: .bold, design: .monospaced)
        }

        static func header(_ size: CGFloat) -> Font {
            .system(size: size, weight: .bold, design: .default)
        }

        static func body(_ size: CGFloat) -> Font {
            .system(size: size, weight: .regular, design: .default)
        }

        static func mono(size: CGFloat) -> Font {
            mono(size)
        }

        static func display(size: CGFloat) -> Font {
            display(size)
        }

        static func header(size: CGFloat) -> Font {
            header(size)
        }

        static func label(size: CGFloat) -> Font {
            label(size)
        }

        static func body(size: CGFloat) -> Font {
            body(size)
        }

        static func tensor(size: CGFloat) -> Font {
            mono(size)
        }

        /// Dynamic Type support
        static func dynamicBody(_ size: CGFloat) -> Font {
            .system(size: size, weight: .regular, design: .default)
        }
    }

    // MARK: - Spacing System (Session 7)
    struct Spacing {
        static let moduleP: CGFloat = 24    // Module padding
        static let cardGap: CGFloat = 16    // Between cards
        static let inlineGap: CGFloat = 8   // Inline elements

        // Legacy (backward compatibility)
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Border Weights (Legacy)
    enum Border {
        static let thin: CGFloat = 1
        static let medium: CGFloat = 2
        static let heavy: CGFloat = 4
    }
}

// MARK: - Color Hex Extension

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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Glow Modifier

extension View {
    func glow(color: Color, radius: CGFloat = 10, opacity: Double = 0.5) -> some View {
        self
            .shadow(color: color.opacity(opacity), radius: radius / 2)
            .shadow(color: color.opacity(opacity * 0.5), radius: radius)
            .shadow(color: color.opacity(opacity * 0.25), radius: radius * 1.5)
    }

    func recoveryGlow(for score: Double) -> some View {
        glow(color: Theme.Colors.recoveryColor(for: score), radius: 15, opacity: 0.4)
    }

    func strainGlow(for score: Double) -> some View {
        glow(color: Theme.Colors.strainColor(for: score), radius: 12, opacity: 0.35)
    }
}

// MARK: - Whoop Design System Dimensions

extension Theme {
    struct Dimensions {
        // Gauges
        static let heroGaugeDiameter: CGFloat = 200
        static let standardGaugeDiameter: CGFloat = 180
        static let smallGaugeDiameter: CGFloat = 100
        static let gaugeStrokeWidth: CGFloat = 12
        static let dashedGaugeStrokeWidth: CGFloat = 4

        // Cards
        static let cardCornerRadius: CGFloat = 12
        static let cardPadding: CGFloat = 16
        static let cardBorderWidth: CGFloat = 1

        // Charts
        static let barChartBarWidth: CGFloat = 24
        static let barChartGap: CGFloat = 8
        static let barChartHeight: CGFloat = 120
        static let lineChartHeight: CGFloat = 100
        static let lineStrokeWidth: CGFloat = 2
        static let dataPointDiameter: CGFloat = 6

        // Rows
        static let activityRowHeight: CGFloat = 64
        static let statsRowHeight: CGFloat = 56
        static let metricTileHeight: CGFloat = 100
        static let smallIconSize: CGFloat = 20
        static let mediumIconSize: CGFloat = 24
    }
}

// MARK: - Legacy View Modifiers

extension View {
    /// Hard-edged border (legacy compatibility)
    func brutalistBorder(_ color: Color = Theme.Colors.borderSubtle, width: CGFloat = Theme.Border.thin) -> some View {
        self.overlay(
            Rectangle()
                .stroke(color, lineWidth: width)
        )
    }

    /// Card style (updated with gradient)
    func brutalistCard() -> some View {
        self
            .background(Theme.Gradients.cardDepth)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Theme.Colors.borderSubtle, lineWidth: 1)
            )
    }

    /// Premium card style with subtle glow
    func premiumCard(accentColor: Color? = nil) -> some View {
        self
            .background(Theme.Gradients.cardDepth)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Theme.Colors.borderSubtle, lineWidth: 1)
            )
            .shadow(color: (accentColor ?? Theme.Colors.borderMedium).opacity(0.1), radius: 8, y: 4)
    }

    /// Uppercase with wide tracking
    func industrialText() -> some View {
        self.textCase(.uppercase)
    }

    /// Whoop-style card with rounded corners and subtle border
    func whoopCard(cornerRadius: CGFloat = Theme.Dimensions.cardCornerRadius) -> some View {
        self
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Theme.Colors.borderSubtle, lineWidth: Theme.Dimensions.cardBorderWidth)
            )
    }

    /// Whoop-style info card with gradient background
    func whoopInfoCard(cornerRadius: CGFloat = Theme.Dimensions.cardCornerRadius) -> some View {
        self
            .background(
                ZStack {
                    Theme.Colors.cardBackgroundAlt
                    Theme.Gradients.infoCard
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Theme.Colors.whoopTeal.opacity(0.3), lineWidth: Theme.Dimensions.cardBorderWidth)
            )
    }

    /// Whoop section header style
    func whoopSectionHeader() -> some View {
        self
            .font(Theme.Fonts.sectionHeader)
            .foregroundColor(Theme.Colors.textSecondary)
            .textCase(.uppercase)
            .tracking(1)
    }
}
