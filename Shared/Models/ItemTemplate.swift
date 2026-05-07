import Foundation

struct ItemTemplate: Codable, Identifiable {
    var id: UUID
    var name: String
    var mode: Mode
    var cycleDays: Int
    var distanceKmBase: Int?   // km at which this car item should be replaced (nil = time-based)
    var notificationDaysBefore: Int
    var isDefault: Bool

    init(
        id: UUID = UUID(),
        name: String,
        mode: Mode,
        cycleDays: Int,
        distanceKmBase: Int? = nil,
        notificationDaysBefore: Int = 3,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.mode = mode
        self.cycleDays = cycleDays
        self.distanceKmBase = distanceKmBase
        self.notificationDaysBefore = notificationDaysBefore
        self.isDefault = isDefault
    }

    // Returns cycle days adjusted for user's household profile
    func adjustedCycleDays(profile: UserProfile) -> Int {
        switch mode {
        case .daily:
            let factor = dailyFamilyFactor(profile.familySize)
            return max(7, Int(Double(cycleDays) / factor))
        case .car:
            if let kmBase = distanceKmBase {
                let monthly = profile.monthlyMileage.kmPerMonth
                return max(7, kmBase * 30 / monthly)
            }
            return cycleDays
        case .gadget:
            return cycleDays
        }
    }

    // Consumption factor relative to a 2-person household baseline
    private func dailyFamilyFactor(_ size: Int) -> Double {
        switch size {
        case 1:  return 0.6
        case 2:  return 1.0
        case 3:  return 1.4
        case 4:  return 1.8
        case 5:  return 2.2
        default: return 2.6
        }
    }
}
