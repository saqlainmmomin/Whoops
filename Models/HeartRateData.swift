import Foundation

// MARK: - Heart Rate Sample

struct HeartRateSample: Identifiable, Codable {
    var id: Date { timestamp }

    let timestamp: Date
    let bpm: Double
    let source: DataSource

    var roundedBPM: Int { Int(bpm.rounded()) }
}

// MARK: - Resting Heart Rate Sample

struct RestingHeartRateSample: Identifiable, Codable {
    var id: Date { date }

    let date: Date
    let bpm: Double
    let source: DataSource

    var roundedBPM: Int { Int(bpm.rounded()) }
}

// MARK: - HRV Sample

struct HRVSample: Identifiable, Codable {
    var id: Date { timestamp }

    let timestamp: Date
    let sdnn: Double  // Standard Deviation of NN intervals (milliseconds)
    let source: DataSource

    var roundedSDNN: Int { Int(sdnn.rounded()) }
}

// MARK: - Respiratory Rate Sample

struct RespiratoryRateSample: Identifiable, Codable {
    var id: Date { timestamp }

    let timestamp: Date
    let breathsPerMinute: Double
    let source: DataSource

    var roundedBreaths: Int { Int(breathsPerMinute.rounded()) }
}

// MARK: - Heart Rate Zone

enum HRZone: Int, CaseIterable, Codable {
    case zone1 = 1  // 50-60% max HR (recovery)
    case zone2 = 2  // 60-70% max HR (fat burn)
    case zone3 = 3  // 70-80% max HR (aerobic)
    case zone4 = 4  // 80-90% max HR (anaerobic)
    case zone5 = 5  // 90-100% max HR (max effort)

    var name: String {
        switch self {
        case .zone1: return "Recovery"
        case .zone2: return "Fat Burn"
        case .zone3: return "Aerobic"
        case .zone4: return "Anaerobic"
        case .zone5: return "Max Effort"
        }
    }

    var percentRange: ClosedRange<Double> {
        switch self {
        case .zone1: return 0.50...0.60
        case .zone2: return 0.60...0.70
        case .zone3: return 0.70...0.80
        case .zone4: return 0.80...0.90
        case .zone5: return 0.90...1.00
        }
    }

    static func zone(for heartRate: Double, maxHeartRate: Double) -> HRZone {
        let percent = heartRate / maxHeartRate
        switch percent {
        case 0..<0.60: return .zone1
        case 0.60..<0.70: return .zone2
        case 0.70..<0.80: return .zone3
        case 0.80..<0.90: return .zone4
        default: return .zone5
        }
    }

    // Strain weight for each zone (higher = more strain contribution)
    var strainWeight: Double {
        switch self {
        case .zone1: return 0.1
        case .zone2: return 0.3
        case .zone3: return 0.6
        case .zone4: return 1.0
        case .zone5: return 1.5
        }
    }
}

// MARK: - Daily Heart Rate Summary

struct DailyHeartRateSummary: Codable {
    let date: Date
    let averageBPM: Double
    let minBPM: Double
    let maxBPM: Double
    let restingBPM: Double?
    let sampleCount: Int

    var roundedAverage: Int { Int(averageBPM.rounded()) }
    var roundedResting: Int? { restingBPM.map { Int($0.rounded()) } }
}

// MARK: - Daily HRV Summary

struct DailyHRVSummary: Codable {
    let date: Date
    let averageSDNN: Double
    let minSDNN: Double
    let maxSDNN: Double
    let nightlySDNN: Double?  // HRV during sleep (most accurate)
    let sampleCount: Int

    var roundedAverage: Int { Int(averageSDNN.rounded()) }
    var roundedNightly: Int? { nightlySDNN.map { Int($0.rounded()) } }
}

// MARK: - HR Recovery Data

struct HRRecoveryData: Codable {
    let workoutEndTime: Date
    let peakHR: Double
    let hr1Min: Double?  // HR 1 minute after workout
    let hr2Min: Double?  // HR 2 minutes after workout
    let hr3Min: Double?  // HR 3 minutes after workout

    var recovery1Min: Double? {
        guard let hr1 = hr1Min else { return nil }
        return peakHR - hr1
    }

    var recovery2Min: Double? {
        guard let hr2 = hr2Min else { return nil }
        return peakHR - hr2
    }

    var recovery3Min: Double? {
        guard let hr3 = hr3Min else { return nil }
        return peakHR - hr3
    }

    // Good recovery is typically > 12 bpm drop in first minute
    var recoveryQuality: RecoveryQuality {
        guard let drop = recovery1Min else { return .unknown }
        switch drop {
        case ..<12: return .belowAverage
        case 12..<20: return .average
        case 20..<30: return .good
        default: return .excellent
        }
    }
}

enum RecoveryQuality: String, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case average = "Average"
    case belowAverage = "Below Average"
    case unknown = "Unknown"
}

// MARK: - Zone Time Distribution

struct ZoneTimeDistribution: Codable {
    let zone1Minutes: Int
    let zone2Minutes: Int
    let zone3Minutes: Int
    let zone4Minutes: Int
    let zone5Minutes: Int

    var totalMinutes: Int {
        zone1Minutes + zone2Minutes + zone3Minutes + zone4Minutes + zone5Minutes
    }

    func minutes(for zone: HRZone) -> Int {
        switch zone {
        case .zone1: return zone1Minutes
        case .zone2: return zone2Minutes
        case .zone3: return zone3Minutes
        case .zone4: return zone4Minutes
        case .zone5: return zone5Minutes
        }
    }

    func percentage(for zone: HRZone) -> Double {
        guard totalMinutes > 0 else { return 0 }
        return Double(minutes(for: zone)) / Double(totalMinutes) * 100
    }

    var weightedStrainMinutes: Double {
        Double(zone1Minutes) * HRZone.zone1.strainWeight +
        Double(zone2Minutes) * HRZone.zone2.strainWeight +
        Double(zone3Minutes) * HRZone.zone3.strainWeight +
        Double(zone4Minutes) * HRZone.zone4.strainWeight +
        Double(zone5Minutes) * HRZone.zone5.strainWeight
    }
}
