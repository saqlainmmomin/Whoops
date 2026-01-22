import Foundation

/// Cache for HealthKit data to reduce redundant queries
/// Uses NSCache for automatic memory management
@MainActor
class HealthKitCache: ObservableObject {
    static let shared = HealthKitCache()

    // MARK: - Cache Storage

    private let metricsCache = NSCache<NSString, CachedMetrics>()
    private let hrCache = NSCache<NSString, CachedHeartRate>()
    private let sleepCache = NSCache<NSString, CachedSleep>()

    // Cache metadata
    private var lastFullRefresh: Date?
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0

    // MARK: - Configuration

    /// Cache expiration time (15 minutes)
    private let cacheExpirationSeconds: TimeInterval = 900

    /// Maximum number of cached items
    private let maxCacheCount = 30

    private init() {
        metricsCache.countLimit = maxCacheCount
        hrCache.countLimit = maxCacheCount
        sleepCache.countLimit = maxCacheCount
    }

    // MARK: - Metrics Cache

    func cacheMetrics(_ metrics: DailyMetrics, for date: Date) {
        let key = cacheKey(for: date)
        let cached = CachedMetrics(metrics: metrics, timestamp: Date())
        metricsCache.setObject(cached, forKey: key as NSString)
    }

    func getCachedMetrics(for date: Date) -> DailyMetrics? {
        let key = cacheKey(for: date)
        guard let cached = metricsCache.object(forKey: key as NSString) else {
            cacheMisses += 1
            return nil
        }

        // Check expiration
        if Date().timeIntervalSince(cached.timestamp) > cacheExpirationSeconds {
            metricsCache.removeObject(forKey: key as NSString)
            cacheMisses += 1
            return nil
        }

        cacheHits += 1
        return cached.metrics
    }

    // MARK: - Heart Rate Cache

    func cacheHeartRate(_ summary: DailyHeartRateSummary, for date: Date) {
        let key = cacheKey(for: date)
        let cached = CachedHeartRate(summary: summary, timestamp: Date())
        hrCache.setObject(cached, forKey: key as NSString)
    }

    func getCachedHeartRate(for date: Date) -> DailyHeartRateSummary? {
        let key = cacheKey(for: date)
        guard let cached = hrCache.object(forKey: key as NSString) else {
            return nil
        }

        if Date().timeIntervalSince(cached.timestamp) > cacheExpirationSeconds {
            hrCache.removeObject(forKey: key as NSString)
            return nil
        }

        return cached.summary
    }

    // MARK: - Sleep Cache

    func cacheSleep(_ summary: DailySleepSummary, for date: Date) {
        let key = cacheKey(for: date)
        let cached = CachedSleep(summary: summary, timestamp: Date())
        sleepCache.setObject(cached, forKey: key as NSString)
    }

    func getCachedSleep(for date: Date) -> DailySleepSummary? {
        let key = cacheKey(for: date)
        guard let cached = sleepCache.object(forKey: key as NSString) else {
            return nil
        }

        if Date().timeIntervalSince(cached.timestamp) > cacheExpirationSeconds {
            sleepCache.removeObject(forKey: key as NSString)
            return nil
        }

        return cached.summary
    }

    // MARK: - Cache Management

    func invalidate(for date: Date) {
        let key = cacheKey(for: date)
        metricsCache.removeObject(forKey: key as NSString)
        hrCache.removeObject(forKey: key as NSString)
        sleepCache.removeObject(forKey: key as NSString)
    }

    func invalidateToday() {
        invalidate(for: Date())
    }

    func invalidateAll() {
        metricsCache.removeAllObjects()
        hrCache.removeAllObjects()
        sleepCache.removeAllObjects()
        lastFullRefresh = nil
        cacheHits = 0
        cacheMisses = 0
    }

    /// Check if a full refresh is needed (more than 15 minutes since last)
    func needsFullRefresh() -> Bool {
        guard let lastRefresh = lastFullRefresh else { return true }
        return Date().timeIntervalSince(lastRefresh) > cacheExpirationSeconds
    }

    func markFullRefresh() {
        lastFullRefresh = Date()
    }

    // MARK: - Statistics

    var hitRate: Double {
        let total = cacheHits + cacheMisses
        guard total > 0 else { return 0 }
        return Double(cacheHits) / Double(total)
    }

    var statistics: CacheStatistics {
        CacheStatistics(
            hits: cacheHits,
            misses: cacheMisses,
            hitRate: hitRate,
            lastRefresh: lastFullRefresh
        )
    }

    // MARK: - Helpers

    private func cacheKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Cache Wrapper Classes

private class CachedMetrics: NSObject {
    let metrics: DailyMetrics
    let timestamp: Date

    init(metrics: DailyMetrics, timestamp: Date) {
        self.metrics = metrics
        self.timestamp = timestamp
    }
}

private class CachedHeartRate: NSObject {
    let summary: DailyHeartRateSummary
    let timestamp: Date

    init(summary: DailyHeartRateSummary, timestamp: Date) {
        self.summary = summary
        self.timestamp = timestamp
    }
}

private class CachedSleep: NSObject {
    let summary: DailySleepSummary
    let timestamp: Date

    init(summary: DailySleepSummary, timestamp: Date) {
        self.summary = summary
        self.timestamp = timestamp
    }
}

// MARK: - Statistics

struct CacheStatistics {
    let hits: Int
    let misses: Int
    let hitRate: Double
    let lastRefresh: Date?

    var formattedHitRate: String {
        String(format: "%.1f%%", hitRate * 100)
    }
}

// MARK: - HealthKitManager Cache Integration

extension HealthKitManager {

    /// Fetch metrics with caching
    func fetchCachedMetrics(for date: Date) async throws -> DailyMetrics? {
        // Check cache first
        if let cached = await HealthKitCache.shared.getCachedMetrics(for: date) {
            return cached
        }

        // Fetch from HealthKit if not cached
        // Note: This is a placeholder - actual implementation would call existing fetch methods
        return nil
    }

    /// Invalidate cache for today (call after new data is recorded)
    func invalidateTodayCache() async {
        await HealthKitCache.shared.invalidateToday()
    }
}
