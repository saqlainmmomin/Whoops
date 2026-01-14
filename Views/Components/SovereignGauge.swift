import SwiftUI

struct SovereignGauge: View {
    let score: Int
    let type: GaugeType
    var size: CGFloat = 200
    
    enum GaugeType {
        case recovery
        case strain
        
        var color: Color {
            switch self {
            case .recovery: return Theme.Colors.neonTeal
            case .strain: return Theme.Colors.neonRed
            }
        }
        
        var gradient: LinearGradient {
            switch self {
            case .recovery: return Theme.Gradients.recovery
            case .strain: return Theme.Gradients.strain
            }
        }
        
        var label: String {
            switch self {
            case .recovery: return "RECOVERY"
            case .strain: return "STRAIN"
            }
        }
        
        var max: Double {
            switch self {
            case .recovery: return 100
            case .strain: return 21
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background Track
            Circle()
                .stroke(Theme.Colors.panelGray, lineWidth: 20)
                .frame(width: size, height: size)
            
            // Progress Track
            Circle()
                .trim(from: 0, to: CGFloat(Double(score) / type.max))
                .stroke(
                    type.gradient,
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(color: type.color.opacity(0.5), radius: 15, x: 0, y: 0) // Neon Glow
            
            // Central Value
            VStack(spacing: 4) {
                Text("\(score)\(type == .recovery ? "%" : "")")
                    .font(Theme.Fonts.header(size: size * 0.25))
                    .foregroundColor(.white)
                
                Text(type.label)
                    .font(Theme.Fonts.label(size: size * 0.08))
                    .foregroundColor(Theme.Colors.textGray)
                    .tracking(2)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            SovereignGauge(score: 82, type: .recovery)
            SovereignGauge(score: 14, type: .strain)
        }
    }
}
