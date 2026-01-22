import SwiftUI

enum BiometricType {
    case hrv, rhr

    var label: String {
        switch self {
        case .hrv: return "HRV"
        case .rhr: return "RHR"
        }
    }

    var unit: String {
        switch self {
        case .hrv: return "ms"
        case .rhr: return "bpm"
        }
    }
}

struct BiometricSatellite: View {
    let type: BiometricType
    let value: Double
    let deviation: Double?

    private var deviationColor: Color {
        guard let dev = deviation else { return Theme.Colors.textTertiary }
        switch type {
        case .hrv: return dev >= 0 ? Theme.Colors.hrvPositive : Theme.Colors.hrvNegative
        case .rhr: return dev <= 0 ? Theme.Colors.rhrPositive : Theme.Colors.rhrNegative
        }
    }

    private var deviationArrow: String {
        guard let dev = deviation else { return "" }
        return dev >= 0 ? "↑" : "↓"
    }

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text("\(Int(value))")
                .font(Theme.Fonts.mono(28))
                .foregroundStyle(Theme.Colors.textPrimary)

            HStack(spacing: 2) {
                Text(type.label)
                    .font(Theme.Fonts.label(10))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .tracking(1)

                Text(type.unit)
                    .font(Theme.Fonts.label(8))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            if let dev = deviation {
                HStack(spacing: 2) {
                    Text(deviationArrow)
                        .font(Theme.Fonts.mono(10))
                    Text("\(abs(Int(dev)))%")
                        .font(Theme.Fonts.mono(10))
                }
                .foregroundStyle(deviationColor)
            }
        }
        .frame(width: 70)
    }
}

#Preview {
    HStack(spacing: 40) {
        BiometricSatellite(type: .hrv, value: 52, deviation: 8)
        BiometricSatellite(type: .hrv, value: 38, deviation: -12)
        BiometricSatellite(type: .rhr, value: 58, deviation: -3)
        BiometricSatellite(type: .rhr, value: 64, deviation: 5)
    }
    .preferredColorScheme(.dark)
    .padding()
    .background(Theme.Colors.void)
}
