import Foundation
import SwiftData

// MARK: - User Profile Model

@Model
final class UserProfile {
    var name: String
    var createdDate: Date

    // HealthKit characteristics (fetched, not user-entered)
    var age: Int?
    var biologicalSex: String?
    var heightCM: Double?
    var weightKG: Double?

    init(name: String) {
        self.name = name
        self.createdDate = Date()
    }

    // Computed properties for display
    var displayHeight: String? {
        guard let height = heightCM else { return nil }
        return String(format: "%.0f cm", height)
    }

    var displayWeight: String? {
        guard let weight = weightKG else { return nil }
        return String(format: "%.1f kg", weight)
    }

    var displayAge: String? {
        guard let age = age else { return nil }
        return "\(age) years"
    }

    // Calculate max HR using age (220 - age formula)
    var estimatedMaxHR: Int? {
        guard let age = age else { return nil }
        return 220 - age
    }
}
