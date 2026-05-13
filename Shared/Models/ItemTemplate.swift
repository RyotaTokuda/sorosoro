import Foundation

struct ItemTemplate: Codable, Identifiable {
    var id: UUID
    var name: String
    var mode: Mode
    var cycleDays: Int
    var distanceKmBase: Int?
    var notificationDaysBefore: Int
    var isDefault: Bool
    var category: String

    init(
        id: UUID = UUID(),
        name: String,
        mode: Mode,
        cycleDays: Int,
        distanceKmBase: Int? = nil,
        notificationDaysBefore: Int = 3,
        isDefault: Bool = false,
        category: String = ""
    ) {
        self.id = id
        self.name = name
        self.mode = mode
        self.cycleDays = cycleDays
        self.distanceKmBase = distanceKmBase
        self.notificationDaysBefore = notificationDaysBefore
        self.isDefault = isDefault
        self.category = category
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, mode, cycleDays, distanceKmBase, notificationDaysBefore, isDefault, category
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        mode = try c.decode(Mode.self, forKey: .mode)
        cycleDays = try c.decode(Int.self, forKey: .cycleDays)
        distanceKmBase = try c.decodeIfPresent(Int.self, forKey: .distanceKmBase)
        notificationDaysBefore = try c.decodeIfPresent(Int.self, forKey: .notificationDaysBefore) ?? 3
        isDefault = try c.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false
        category = try c.decodeIfPresent(String.self, forKey: .category) ?? ""
    }

    // Returns cycle days adjusted for user's household profile
    func adjustedCycleDays(profile: UserProfile) -> Int {
        switch mode {
        case .daily, .gadget:
            let factor = profile.effectiveFamilyFactor
            return max(7, Int(Double(cycleDays) / factor))
        case .car:
            if let kmBase = distanceKmBase {
                let monthly = profile.monthlyMileage.kmPerMonth
                return max(7, kmBase * 30 / monthly)
            }
            return cycleDays
        case .pet, .health:
            return cycleDays
        }
    }
}
