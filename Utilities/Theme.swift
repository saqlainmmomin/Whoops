import SwiftUI

struct Theme {
    struct Colors {
        static let sovereignBlack = Color(hex: "000000")
        static let sovereignDarkGray = Color(hex: "121212")
        static let panelGray = Color(hex: "1C1C1E")
        
        // Neon Accents
        static let neonTeal = Color(hex: "00E5FF") // Recovery
        static let neonRed = Color(hex: "FF003C")   // Strain
        static let neonGreen = Color(hex: "00FF94") // Sleep/Good
        static let neonGold = Color(hex: "FFD700")  // Warning
        
        static let textWhite = Color(hex: "FFFFFF")
        static let textGray = Color(hex: "A0A0A0")
    }
    
    struct Fonts {
        static func tensor(size: CGFloat) -> Font {
            .system(size: size, weight: .regular, design: .monospaced)
        }
        
        static func header(size: CGFloat) -> Font {
            .system(size: size, weight: .bold, design: .rounded)
        }
        
        static func label(size: CGFloat) -> Font {
            .system(size: size, weight: .medium, design: .default)
        }
    }
    
    struct Gradients {
        static let recovery = LinearGradient(
            colors: [Colors.neonTeal, Color(hex: "0088AA")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let strain = LinearGradient(
            colors: [Colors.neonRed, Color(hex: "AA0022")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// Helper for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
