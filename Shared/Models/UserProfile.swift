import Foundation

enum VehicleType: String, Codable, CaseIterable, Identifiable {
    case gasoline
    case diesel
    case hev
    case ev

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gasoline: "ガソリン車"
        case .diesel:   "ディーゼル車"
        case .hev:      "ハイブリッド車"
        case .ev:       "電気自動車"
        }
    }
}

enum MonthlyMileage: String, Codable, CaseIterable, Identifiable {
    case low    // ~500km
    case medium // 500~1500km
    case high   // 1500km~

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low:    "〜500km"
        case .medium: "500〜1500km"
        case .high:   "1500km〜"
        }
    }

    // Representative km/month used for cycle calculation
    var kmPerMonth: Int {
        switch self {
        case .low:    300
        case .medium: 1000
        case .high:   2000
        }
    }
}

struct UserProfile: Codable {
    var visibleModes: [Mode]
    var familySize: Int
    var monthlyMileage: MonthlyMileage
    var vehicleType: VehicleType
    var hasCompletedOnboarding: Bool

    init(
        visibleModes: [Mode] = Mode.allCases,
        familySize: Int = 2,
        monthlyMileage: MonthlyMileage = .medium,
        vehicleType: VehicleType = .gasoline,
        hasCompletedOnboarding: Bool = false
    ) {
        self.visibleModes = visibleModes
        self.familySize = familySize
        self.monthlyMileage = monthlyMileage
        self.vehicleType = vehicleType
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
