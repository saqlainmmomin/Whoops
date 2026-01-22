import SwiftUI

/// Horizontal bar chart for sleep timeline visualization
/// Shows bedtime-to-wake windows for each day of the week
struct WeekBarChart: View {
    let sleepData: [DailySleepBar]  // 7 days
    let selectedDay: Date?
    let onDayTap: (Date) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Time scale header
            HStack {
                Text("")
                    .frame(width: 50)
                Spacer()
                Text("8PM")
                    .font(Theme.Fonts.label(10))
                    .foregroundColor(Theme.Colors.textTertiary)
                Spacer()
                Text("12AM")
                    .font(Theme.Fonts.label(10))
                    .foregroundColor(Theme.Colors.textTertiary)
                Spacer()
                Text("4AM")
                    .font(Theme.Fonts.label(10))
                    .foregroundColor(Theme.Colors.textTertiary)
                Spacer()
                Text("8AM")
                    .font(Theme.Fonts.label(10))
                    .foregroundColor(Theme.Colors.textTertiary)
            }
            .padding(.horizontal, 4)

            ForEach(sleepData) { day in
                HStack(spacing: 12) {
                    // Day label (Aug 23)
                    Text(day.date.formatted(.dateTime.month(.abbreviated).day()))
                        .font(Theme.Fonts.label(11))
                        .foregroundColor(
                            selectedDay != nil && Calendar.current.isDate(day.date, inSameDayAs: selectedDay!)
                                ? Theme.Colors.textPrimary
                                : Theme.Colors.textSecondary
                        )
                        .frame(width: 50, alignment: .leading)

                    // Sleep bar
                    GeometryReader { geo in
                        let startOffset = bedtimeOffset(day.bedtime)
                        let duration = sleepDuration(from: day.bedtime, to: day.wakeTime)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(day.performanceColor)
                            .frame(width: max(duration * geo.size.width, 4))
                            .offset(x: startOffset * geo.size.width)
                    }
                    .frame(height: 20)
                    .background(Theme.Colors.tertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .contentShape(Rectangle())
                .onTapGesture { onDayTap(day.date) }
                .opacity(
                    selectedDay == nil || Calendar.current.isDate(day.date, inSameDayAs: selectedDay!)
                        ? 1.0
                        : 0.5
                )
            }
        }
    }

    /// Calculate bedtime offset as percentage of 12-hour window (8PM to 8AM)
    private func bedtimeOffset(_ bedtime: Date) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: bedtime)
        let minute = calendar.component(.minute, from: bedtime)

        // Convert to minutes from 8PM (20:00)
        var minutesFrom8PM: Int
        if hour >= 20 {
            // Same day evening (20:00-23:59)
            minutesFrom8PM = (hour - 20) * 60 + minute
        } else if hour < 8 {
            // Next day morning (00:00-07:59)
            minutesFrom8PM = (hour + 4) * 60 + minute  // 4 hours = 20:00 to 00:00
        } else {
            // Day time (unusual bedtime)
            minutesFrom8PM = 0
        }

        // 12 hours = 720 minutes total window
        return CGFloat(minutesFrom8PM) / 720.0
    }

    /// Calculate sleep duration as percentage of 12-hour window
    private func sleepDuration(from bedtime: Date, to wakeTime: Date) -> CGFloat {
        let duration = wakeTime.timeIntervalSince(bedtime)
        let durationMinutes = duration / 60

        // 12 hours = 720 minutes total window
        return min(CGFloat(durationMinutes) / 720.0, 1.0)
    }
}

/// Data model for a single day's sleep bar
struct DailySleepBar: Identifiable {
    let id = UUID()
    let date: Date
    let bedtime: Date
    let wakeTime: Date
    let performanceColor: Color

    /// Create from SleepAnalysis
    static func from(_ analysis: SleepAnalysis, date: Date) -> DailySleepBar {
        DailySleepBar(
            date: date,
            bedtime: analysis.bedtime,
            wakeTime: analysis.wakeTime,
            performanceColor: Theme.Colors.sleepPerformance(score: Int(analysis.performanceScore))
        )
    }

    /// Create from DailySleepSummary
    static func from(_ summary: DailySleepSummary) -> DailySleepBar? {
        guard let bedtime = summary.bedtime,
              let wakeTime = summary.wakeTime else {
            return nil
        }

        // Calculate performance color based on efficiency
        let performanceScore = Int(summary.averageEfficiency)
        return DailySleepBar(
            date: summary.date,
            bedtime: bedtime,
            wakeTime: wakeTime,
            performanceColor: Theme.Colors.sleepPerformance(score: performanceScore)
        )
    }
}

// MARK: - Sleep Stages Card

/// Card showing sleep stage breakdown
struct SleepStagesCard: View {
    let sleep: SleepAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SLEEP STAGES")
                .font(Theme.Fonts.label(11))
                .tracking(1)
                .foregroundColor(Theme.Colors.textSecondary)

            // Segmented bar
            SegmentedProgressBar(segments: [
                SegmentedProgressBar.Segment(
                    label: "Deep",
                    value: Double(sleep.stages.deepMinutes) / Double(max(sleep.stages.totalMinutes, 1)),
                    color: Color(hex: "#5B21B6")
                ),
                SegmentedProgressBar.Segment(
                    label: "REM",
                    value: Double(sleep.stages.remMinutes) / Double(max(sleep.stages.totalMinutes, 1)),
                    color: Color(hex: "#7C3AED")
                ),
                SegmentedProgressBar.Segment(
                    label: "Core",
                    value: Double(sleep.stages.coreMinutes) / Double(max(sleep.stages.totalMinutes, 1)),
                    color: Color(hex: "#A78BFA")
                ),
                SegmentedProgressBar.Segment(
                    label: "Awake",
                    value: Double(sleep.stages.awakeMinutes) / Double(max(sleep.stages.totalMinutes, 1)),
                    color: Theme.Colors.textTertiary
                )
            ])

            // Legend
            HStack(spacing: 16) {
                StageLegendItem(label: "Deep", minutes: sleep.stages.deepMinutes, color: Color(hex: "#5B21B6"))
                StageLegendItem(label: "REM", minutes: sleep.stages.remMinutes, color: Color(hex: "#7C3AED"))
                StageLegendItem(label: "Core", minutes: sleep.stages.coreMinutes, color: Color(hex: "#A78BFA"))
                StageLegendItem(label: "Awake", minutes: sleep.stages.awakeMinutes, color: Theme.Colors.textTertiary)
            }
        }
        .padding(Theme.Spacing.cardGap)
        .background(Theme.Colors.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Legend item for sleep stage
private struct StageLegendItem: View {
    let label: String
    let minutes: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(Theme.Fonts.label(10))
                    .foregroundColor(Theme.Colors.textSecondary)
                Text("\(minutes)m")
                    .font(Theme.Fonts.display(12))
                    .foregroundColor(Theme.Colors.textPrimary)
            }
        }
    }
}

// MARK: - Preview

#Preview("Week Bar Chart") {
    let calendar = Calendar.current
    let today = Date()

    let sampleData = (0..<7).map { offset -> DailySleepBar in
        let date = calendar.date(byAdding: .day, value: -offset, to: today)!
        let bedtime = calendar.date(bySettingHour: 22 + Int.random(in: -1...1), minute: Int.random(in: 0...59), second: 0, of: date)!
        let wakeTime = calendar.date(byAdding: .hour, value: 7 + Int.random(in: -1...1), to: bedtime)!

        return DailySleepBar(
            date: date,
            bedtime: bedtime,
            wakeTime: wakeTime,
            performanceColor: Theme.Colors.sleepPerformance(score: Int.random(in: 60...95))
        )
    }.reversed()

    return WeekBarChart(
        sleepData: Array(sampleData),
        selectedDay: nil,
        onDayTap: { _ in }
    )
    .frame(height: 200)
    .padding()
    .background(Theme.Colors.primary)
}
