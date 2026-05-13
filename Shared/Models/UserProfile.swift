import Foundation

enum VehicleType: String, Codable, CaseIterable, Identifiable {
    case gasoline
    case diesel
    case hev
    case ev

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gasoline: String(localized: "vehicle.gasoline")
        case .diesel:   String(localized: "vehicle.diesel")
        case .hev:      String(localized: "vehicle.hev")
        case .ev:       String(localized: "vehicle.ev")
        }
    }
}

enum MonthlyMileage: String, Codable, CaseIterable, Identifiable {
    case very_low  // ~300km
    case low       // 300~600km
    case medium    // 600~1000km
    case high      // 1000~1500km
    case very_high // 1500km~

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .very_low:  String(localized: "mileage.very_low")
        case .low:       String(localized: "mileage.low")
        case .medium:    String(localized: "mileage.medium")
        case .high:      String(localized: "mileage.high")
        case .very_high: String(localized: "mileage.very_high")
        }
    }

    var kmPerMonth: Int {
        switch self {
        case .very_low:  200
        case .low:       450
        case .medium:    800
        case .high:      1250
        case .very_high: 2000
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
