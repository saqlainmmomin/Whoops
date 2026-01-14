import SwiftUI

struct StrainCard: View {
    let score: StrainScore?
    let trend: TrendDirection?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(scoreColor)
                Text("Strain")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                ConfidenceIndicator(confidence: score?.confidence ?? .low, compact: true)
            }

            // Score
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(score?.score ?? 0)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))

                if let trend = trend {
                    TrendIndicator(direction: trend, compact: true)
                }
            }

            // Category
            Text(score?.category.rawValue ?? "No Activity")
                .font(.caption)
                .foregroundColor(.secondary)

            // Mini progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                        .cornerRadius(3)

                    Rectangle()
                        .fill(scoreColor)
                        .frame(width: geometry.size.width * CGFloat(score?.score ?? 0) / 100, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var scoreColor: Color {
        guard let score = score?.score else { return .gray }
        switch score {
        case 0...33: return .blue
        case 34...66: return .orange
        default: return .red
        }
    }
}

#Preview {
    HStack {
        StrainCard(
            score: StrainScore(
                score: 45,
                confidence: .medium,
                zoneComponent: ScoreComponent(name: "Zone", rawValue: 35, normalizedValue: 50, weight: 0.5, contribution: 25),
                durationComponent: ScoreComponent(name: "Duration", rawValue: 30, normalizedValue: 50, weight: 0.3, contribution: 15),
                energyComponent: ScoreComponent(name: "Energy", rawValue: 110, normalizedValue: 55, weight: 0.2, contribution: 11)
            ),
            trend: .stable
        )

        StrainCard(score: nil, trend: nil)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
