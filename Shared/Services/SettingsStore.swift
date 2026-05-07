import Foundation

@Observable
final class SettingsStore {
    private(set) var settings: AppSettings
    private let fileURL: URL

    init() {
        fileURL = AppConstants.sharedContainerURL
            .appendingPathComponent(AppConstants.settingsFileName)
        settings = AppSettings()
        load()
    }

    // MARK: - Update

    func setSelectedMode(_ mode: Mode) {
        settings.selectedMode = mode
        save()
    }

    func setGlobalNotification(_ enabled: Bool) {
        settings.globalNotificationEnabled = enabled
        save()
    }

    func setDefaultNotificationDays(_ days: Int) {
        settings.defaultNotificationDaysBefore = days
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            settings = try JSONDecoder().decode(AppSettings.self, from: data)
        } catch {
            print("[SettingsStore] load error: \(error)")
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(settings)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[SettingsStore] save error: \(error)")
        }
    }
}
