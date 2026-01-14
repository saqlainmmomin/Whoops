import Foundation

// MARK: - Sleep Stage

enum SleepStage: String, CaseIterable, Codable {
    case awake = "Awake"
    case rem = "REM"
    case core = "Core"
    case deep = "Deep"
    case unspecified = "Asleep"
    case inBed = "In Bed"

    var isAsleep: Bool {
        switch self {
        case .rem, .core, .deep, .unspecified:
            return true
        case .awake, .inBed:
            return false
        }
    }

    var displayOrder: Int {
        switch self {
        case .deep: return 0
        case .core: return 1
        case .rem: return 2
        case .awake: return 3
        case .unspecified: return 4
        case .inBed: return 5
        }
    }

    // Sleep quality weight (higher = better quality sleep)
    var qualityWeight: Double {
        switch self {
        case .deep: return 1.5
        case .rem: return 1.3
        case .core: return 1.0
        case .unspecified: return 0.8
        case .awake: return 0.0
        case .inBed: return 0.0
        }
    }
}

// MARK: - Sleep Sample

struct SleepSample: Identifiable, Codable {
    var id: Date { startDate }

    let startDate: Date
    let endDate: Date
    let stage: SleepStage
    let source: DataSource

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var durationMinutes: Int {
        Int(duration / 60)
    }
}

// MARK: - Sleep Session (Consolidated Sleep Period)

struct SleepSession: Identifiable, Codable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let samples: [SleepSample]

    var totalDuration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var totalDurationHours: Double {
        totalDuration / 3600
    }

    var asleepDuration: TimeInterval {
        samples.filter { $0.stage.isAsleep }.reduce(0) { $0 + $1.duration }
    }

    var asleepDurationHours: Double {
        asleepDuration / 3600
    }

    // Sleep efficiency: time asleep / time in bed
    var efficiency: Double {
        guard totalDuration > 0 else { return 0 }
        return asleepDuration / totalDuration * 100
    }

    var stageBreakdown: SleepStageBreakdown {
        var breakdown = SleepStageBreakdown()

        for sample in samples {
            let minutes = sample.durationMinutes
            switch sample.stage {
            case .deep:
                breakdown.deepMinutes += minutes
            case .core:
                breakdown.coreMinutes += minutes
            case .rem:
                breakdown.remMinutes += minutes
            case .awake:
                breakdown.awakeMinutes += minutes
            case .unspecified:
                breakdown.unspecifiedMinutes += minutes
            case .inBed:
                break // Don't count in bed time
            }
        }

        return breakdown
    }

    // Count sleep interruptions (awake periods during sleep)
    var interruptionCount: Int {
        var count = 0
        var wasAsleep = false

        for sample in samples.sorted(by: { $0.startDate < $1.startDate }) {
            if sample.stage == .awake && wasAsleep {
                count += 1
            }
            wasAsleep = sample.stage.isAsleep
        }

        return count
    }
}

// MARK: - Sleep Stage Breakdown

struct SleepStageBreakdown: Codable {
    var deepMinutes: Int = 0
    var coreMinutes: Int = 0
    var remMinutes: Int = 0
    var awakeMinutes: Int = 0
    var unspecifiedMinutes: Int = 0

    var totalAsleepMinutes: Int {
        deepMinutes + coreMinutes + remMinutes + unspecifiedMinutes
    }

    var totalMinutes: Int {
        totalAsleepMinutes + awakeMinutes
    }

    // Percentages of time asleep
    var deepPercentage: Double {
        guard totalAsleepMinutes > 0 else { return 0 }
        return Double(deepMinutes) / Double(totalAsleepMinutes) * 100
    }

    var corePercentage: Double {
        guard totalAsleepMinutes > 0 else { return 0 }
        return Double(coreMinutes) / Double(totalAsleepMinutes) * 100
    }

    var remPercentage: Double {
        guard totalAsleepMinutes > 0 else { return 0 }
        return Double(remMinutes) / Double(totalAsleepMinutes) * 100
    }

    // Ideal ranges (based on sleep science)
    // Deep: 13-23%, REM: 20-25%, Light/Core: 50-60%
    var deepInRange: Bool { deepPercentage >= 13 && deepPercentage <= 23 }
    var remInRange: Bool { remPercentage >= 20 && remPercentage <= 25 }
    var coreInRange: Bool { corePercentage >= 50 && corePercentage <= 60 }
}

// MARK: - Daily Sleep Summary

struct DailySleepSummary: Codable {
    let date: Date
    let sessions: [SleepSession]

    var primarySession: SleepSession? {
        // Return the longest sleep session (main sleep)
        sessions.max(by: { $0.totalDuration < $1.totalDuration })
    }

    var totalSleepDuration: TimeInterval {
        sessions.reduce(0) { $0 + $1.asleepDuration }
    }

    var totalSleepHours: Double {
        totalSleepDuration / 3600
    }

    var averageEfficiency: Double {
        guard !sessions.isEmpty else { return 0 }
        return sessions.reduce(0) { $0 + $1.efficiency } / Double(sessions.count)
    }

    var bedtime: Date? {
        primarySession?.startDate
    }

    var wakeTime: Date? {
        primarySession?.endDate
    }

    var combinedStageBreakdown: SleepStageBreakdown {
        var combined = SleepStageBreakdown()
        for session in sessions {
            let breakdown = session.stageBreakdown
            combined.deepMinutes += breakdown.deepMinutes
            combined.coreMinutes += breakdown.coreMinutes
            combined.remMinutes += breakdown.remMinutes
            combined.awakeMinutes += breakdown.awakeMinutes
            combined.unspecifiedMinutes += breakdown.unspecifiedMinutes
        }
        return combined
    }

    var totalInterruptions: Int {
        sessions.reduce(0) { $0 + $1.interruptionCount }
    }
}

// MARK: - Sleep Timing

struct SleepTiming: Codable {
    let bedtime: Date
    let wakeTime: Date

    var bedtimeHour: Int {
        Calendar.current.component(.hour, from: bedtime)
    }

    var wakeTimeHour: Int {
        Calendar.current.component(.hour, from: wakeTime)
    }

    // Minutes since midnight for bedtime (can be negative for before midnight)
    var bedtimeMinutesSinceMidnight: Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: bedtime)
        let minute = calendar.component(.minute, from: bedtime)

        // If hour >= 12, it's evening (negative offset from next midnight)
        if hour >= 12 {
            return (hour - 24) * 60 + minute
        } else {
            return hour * 60 + minute
        }
    }

    // Minutes since midnight for wake time
    var wakeTimeMinutesSinceMidnight: Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: wakeTime)
        let minute = calendar.component(.minute, from: wakeTime)
        return hour * 60 + minute
    }
}

// MARK: - Sleep Debt

struct SleepDebt: Codable {
    let actualSleepHours: Double
    let baselineSleepHours: Double  // 7-day average

    var debtHours: Double {
        baselineSleepHours - actualSleepHours
    }

    var debtRatio: Double {
        guard baselineSleepHours > 0 else { return 1.0 }
        return actualSleepHours / baselineSleepHours
    }

    var status: SleepDebtStatus {
        switch debtRatio {
        case ..<0.80: return .significant
        case 0.80..<0.95: return .moderate
        case 0.95..<1.05: return .balanced
        default: return .surplus
        }
    }
}

enum SleepDebtStatus: String, Codable {
    case significant = "Significant Debt"
    case moderate = "Moderate Debt"
    case balanced = "Balanced"
    case surplus = "Surplus"
}
