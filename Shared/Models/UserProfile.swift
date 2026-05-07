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
    var adultsCount: Int
    var childrenCount: Int
    var monthlyMileage: MonthlyMileage
    var vehicleType: VehicleType
    var hasCompletedOnboarding: Bool

    // Baseline = 2 adults; children consume ~60% of an adult
    var effectiveFamilyFactor: Double {
        let effective = Double(adultsCount) + Double(childrenCount) * 0.6
        return effective / 2.0
    }

    init(
        visibleModes: [Mode] = Mode.allCases,
        adultsCount: Int = 2,
        childrenCount: Int = 0,
        monthlyMileage: MonthlyMileage = .medium,
        vehicleType: VehicleType = .gasoline,
        hasCompletedOnboarding: Bool = false
    ) {
        self.visibleModes = visibleModes
        self.adultsCount = adultsCount
        self.childrenCount = childrenCount
        self.monthlyMileage = monthlyMileage
        self.vehicleType = vehicleType
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }

    // Custom Codable: migrates from old single `familySize` key
    enum CodingKeys: String, CodingKey {
        case visibleModes, adultsCount, childrenCount
        case monthlyMileage, vehicleType, hasCompletedOnboarding
        case legacyFamilySize = "familySize"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        visibleModes = try c.decode([Mode].self, forKey: .visibleModes)
        if (try? c.decode(Int.self, forKey: .adultsCount)) == nil,
           let legacy = try? c.decode(Int.self, forKey: .legacyFamilySize) {
            adultsCount = legacy
            childrenCount = 0
        } else {
            adultsCount = try c.decodeIfPresent(Int.self, forKey: .adultsCount) ?? 2
            childrenCount = try c.decodeIfPresent(Int.self, forKey: .childrenCount) ?? 0
        }
        monthlyMileage = try c.decodeIfPresent(MonthlyMileage.self, forKey: .monthlyMileage) ?? .medium
        vehicleType = try c.decodeIfPresent(VehicleType.self, forKey: .vehicleType) ?? .gasoline
        hasCompletedOnboarding = try c.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(visibleModes, forKey: .visibleModes)
        try c.encode(adultsCount, forKey: .adultsCount)
        try c.encode(childrenCount, forKey: .childrenCount)
        try c.encode(monthlyMileage, forKey: .monthlyMileage)
        try c.encode(vehicleType, forKey: .vehicleType)
        try c.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
    }
}
