import SwiftUI

struct SleepCard: View {
    let sleepSummary: DailySleepSummary?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundColor(.purple)
                Text("Sleep")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()
            }

            if let sleep = sleepSummary {
                // Duration
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formatHours(sleep.totalSleepHours))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                }

                // Efficiency
                if sleep.averageEfficiency > 0 {
                    HStack(spacing: 4) {
                        Text("\(Int(sleep.averageEfficiency))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(efficiencyColor(sleep.averageEfficiency))

                        Text("efficiency")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Stage breakdown mini
                stageBreakdown(sleep.combinedStageBreakdown)
            } else {
                // No data state
                Text("--")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)

                Text("No sleep data")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    // MARK: - Stage Breakdown

    private func stageBreakdown(_ breakdown: SleepStageBreakdown) -> some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                if breakdown.deepMinutes > 0 {
                    stageBar(
                        width: stageWidth(breakdown.deepMinutes, total: breakdown.totalAsleepMinutes, totalWidth: geometry.size.width),
                        color: .indigo,
                        label: "Deep"
                    )
                }
                if breakdown.coreMinutes > 0 {
                    stageBar(
                        width: stageWidth(breakdown.coreMinutes, total: breakdown.totalAsleepMinutes, totalWidth: geometry.size.width),
                        color: .blue,
                        label: "Core"
                    )
                }
                if breakdown.remMinutes > 0 {
                    stageBar(
                        width: stageWidth(breakdown.remMinutes, total: breakdown.totalAsleepMinutes, totalWidth: geometry.size.width),
                        color: .cyan,
                        label: "REM"
                    )
                }
            }
        }
        .frame(height: 8)
    }

    private func stageBar(width: CGFloat, color: Color, label: String) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: max(width, 4))
            .cornerRadius(2)
    }

    private func stageWidth(_ minutes: Int, total: Int, totalWidth: CGFloat) -> CGFloat {
        guard total > 0 else { return 0 }
        return (CGFloat(minutes) / CGFloat(total)) * totalWidth
    }

    // MARK: - Helpers

    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }

    private func efficiencyColor(_ efficiency: Double) -> Color {
        switch efficiency {
        case 90...: return .green
        case 80..<90: return .yellow
        default: return .orange
        }
    }
}

#Preview {
    HStack {
        SleepCard(
            sleepSummary: DailySleepSummary(
                date: Date(),
                sessions: [
                    SleepSession(
                        id: UUID(),
                        startDate: Date().adding(hours: -8),
                        endDate: Date(),
                        samples: []
                    )
                ]
            )
        )

        SleepCard(sleepSummary: nil)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
