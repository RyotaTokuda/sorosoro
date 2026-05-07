import Foundation

struct AppSettings: Codable {
    var selectedMode: Mode
    var globalNotificationEnabled: Bool
    var defaultNotificationDaysBefore: Int

    init(
        selectedMode: Mode = .daily,
        globalNotificationEnabled: Bool = true,
        defaultNotificationDaysBefore: Int = 3
    ) {
        self.selectedMode = selectedMode
        self.globalNotificationEnabled = globalNotificationEnabled
        self.defaultNotificationDaysBefore = defaultNotificationDaysBefore
    }
}
