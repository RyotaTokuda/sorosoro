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
            let factor = profile.effectiveFamilyFactor
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
}
