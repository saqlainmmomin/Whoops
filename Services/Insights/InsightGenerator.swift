import Foundation
import SwiftUI

@MainActor
class InsightGenerator {

    static let shared = InsightGenerator()

    private init() {}

    func generateInsights(metrics: DailyMetrics, baseline: Baseline?) -> [Insight] {
        var insights: [Insight] = []

        // HRV insights
        if let baseline = baseline, let hrv = metrics.hrv {
            let hrvValue = hrv.nightlySDNN ?? hrv.averageSDNN
            if let avgHRV = baseline.averageHRV {
                let hrvDev = ((hrvValue - avgHRV) / avgHRV) * 100

                if hrvDev > 10 {
                    insights.append(Insight(
                        icon: "arrow.up.heart.fill",
                        headline: "Elevated HRV",
                        detail: "HRV is \(Int(hrvDev))% above baseline. Good day for intensity.",
                        accentColor: Theme.Colors.hrvPositive
                    ))
                } else if hrvDev < -15 {
                    insights.append(Insight(
                        icon: "arrow.down.heart.fill",
                        headline: "Low HRV",
                        detail: "HRV is \(Int(abs(hrvDev)))% below baseline. Consider lighter activity.",
                        accentColor: Theme.Colors.hrvNegative
                    ))
                }
            }
        }

        // Recovery insights
        if let recovery = metrics.recoveryScore {
            if recovery.score >= 85 {
                insights.append(Insight(
                    icon: "bolt.fill",
                    headline: "Peak Recovery",
                    detail: "Your body is primed for peak performance.",
                    accentColor: Theme.Colors.recoveryPeak
                ))
            } else if recovery.score < 33 {
                insights.append(Insight(
                    icon: "bed.double.fill",
                    headline: "Low Recovery",
                    detail: "Consider rest or light activity today.",
                    accentColor: Theme.Colors.recoveryLow
                ))
            }
        }

        // Sleep insights
        if let sleep = metrics.sleep {
            if sleep.totalSleepHours < 6 {
                insights.append(Insight(
                    icon: "moon.fill",
                    headline: "Sleep Deficit",
                    detail: "You got \(String(format: "%.1f", sleep.totalSleepHours))h of sleep. Aim for 7-9 hours.",
                    accentColor: Theme.Colors.sleepPoor
                ))
            } else if sleep.totalSleepHours >= 8 {
                insights.append(Insight(
                    icon: "moon.stars.fill",
                    headline: "Great Sleep",
                    detail: "You got \(String(format: "%.1f", sleep.totalSleepHours))h of quality rest.",
                    accentColor: Theme.Colors.sleepOptimal
                ))
            }
        }

        // Strain insights
        if let strain = metrics.strainScore {
            if strain.score >= 80 {
                insights.append(Insight(
                    icon: "flame.fill",
                    headline: "High Strain Day",
                    detail: "You've accumulated significant cardiovascular load today.",
                    accentColor: Theme.Colors.strainOverreach
                ))
            }
        }

        // RHR insights
        if let baseline = baseline, let heartRate = metrics.heartRate {
            if let avgRHR = baseline.averageRestingHR, let rhr = heartRate.restingBPM {
                let rhrDev = rhr - avgRHR

                if rhrDev > 5 {
                    insights.append(Insight(
                        icon: "heart.fill",
                        headline: "Elevated Resting HR",
                        detail: "RHR is \(Int(rhrDev)) bpm above baseline. May indicate stress or incomplete recovery.",
                        accentColor: Theme.Colors.rhrNegative
                    ))
                } else if rhrDev < -5 {
                    insights.append(Insight(
                        icon: "heart.fill",
                        headline: "Low Resting HR",
                        detail: "RHR is \(Int(abs(rhrDev))) bpm below baseline. Good sign of fitness adaptation.",
                        accentColor: Theme.Colors.rhrPositive
                    ))
                }
            }
        }

        return insights
    }

    func getPrimaryInsight(metrics: DailyMetrics, baseline: Baseline?) -> Insight? {
        let insights = generateInsights(metrics: metrics, baseline: baseline)

        // Priority: Peak Recovery > Low Recovery > Low HRV > High Strain > Others
        if let peakRecovery = insights.first(where: { $0.headline == "Peak Recovery" }) {
            return peakRecovery
        }
        if let lowRecovery = insights.first(where: { $0.headline == "Low Recovery" }) {
            return lowRecovery
        }
        if let lowHRV = insights.first(where: { $0.headline == "Low HRV" }) {
            return lowHRV
        }
        if let highStrain = insights.first(where: { $0.headline == "High Strain Day" }) {
            return highStrain
        }

        return insights.first
    }
}
