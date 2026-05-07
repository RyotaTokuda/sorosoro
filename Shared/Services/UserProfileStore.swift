import Foundation

@Observable
@MainActor
final class UserProfileStore {

    private(set) var profile: UserProfile = .init()

    private let url: URL = AppConstants.sharedContainerURL
        .appendingPathComponent("user_profile.json")

    init() { load() }

    func setVisibleModes(_ modes: [Mode]) {
        profile.visibleModes = modes.isEmpty ? [.daily] : modes
        save()
    }

    func setFamilySize(_ size: Int) {
        profile.familySize = max(1, size)
        save()
    }

    func setMonthlyMileage(_ mileage: MonthlyMileage) {
        profile.monthlyMileage = mileage
        save()
    }

    func setVehicleType(_ type: VehicleType) {
        profile.vehicleType = type
        save()
    }

    func completeOnboarding(
        visibleModes: [Mode],
        familySize: Int,
        monthlyMileage: MonthlyMileage,
        vehicleType: VehicleType
    ) {
        profile.visibleModes = visibleModes.isEmpty ? [.daily] : visibleModes
        profile.familySize = max(1, familySize)
        profile.monthlyMileage = monthlyMileage
        profile.vehicleType = vehicleType
        profile.hasCompletedOnboarding = true
        save()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        profile = (try? decoder.decode(UserProfile.self, from: data)) ?? .init()
    }

    private func save() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(profile) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
