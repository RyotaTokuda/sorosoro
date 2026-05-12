import Foundation

enum Mode: String, Codable, CaseIterable, Identifiable {
    case daily = "daily"
    case car = "car"
    case gadget = "gadget"  // kept for Codable backward compat; merged into daily in UI

    // Gadget is hidden as a tab — existing items with mode=.gadget appear in the daily list
    static var allCases: [Mode] { [.daily, .car] }

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: String(localized: "mode.daily")
        case .car: String(localized: "mode.car")
        case .gadget: String(localized: "mode.gadget")
        }
    }

    var iconName: String {
        switch self {
        case .daily: "house.fill"
        case .car: "car.fill"
        case .gadget: "desktopcomputer"
        }
    }

    var colorName: String {
        switch self {
        case .daily: "blue"
        case .car: "green"
        case .gadget: "purple"
        }
    }
}
