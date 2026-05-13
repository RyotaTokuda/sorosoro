import Foundation

enum Mode: String, Codable, CaseIterable, Identifiable {
    case daily = "daily"
    case car = "car"
    case pet = "pet"
    case health = "health"
    case gadget = "gadget"  // kept for Codable backward compat; merged into daily in UI

    // Gadget is hidden as a tab — existing items with mode=.gadget appear in the daily list
    static var allCases: [Mode] { [.daily, .car, .pet, .health] }

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily:  String(localized: "mode.daily")
        case .car:    String(localized: "mode.car")
        case .pet:    String(localized: "mode.pet")
        case .health: String(localized: "mode.health")
        case .gadget: String(localized: "mode.gadget")
        }
    }

    var iconName: String {
        switch self {
        case .daily:  "house.fill"
        case .car:    "car.fill"
        case .pet:    "pawprint.fill"
        case .health: "heart.fill"
        case .gadget: "desktopcomputer"
        }
    }

    var colorName: String {
        switch self {
        case .daily:  "blue"
        case .car:    "green"
        case .pet:    "orange"
        case .health: "pink"
        case .gadget: "purple"
        }
    }
}
