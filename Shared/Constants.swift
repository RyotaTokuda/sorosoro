import Foundation

enum AppConstants {
    static let appGroupID = "group.com.mankai.sorosoro"
    static let itemsFileName = "items.json"
    static let shoppingListFileName = "shopping_list.json"
    static let customTemplatesFileName = "custom_templates.json"
    static let settingsFileName = "settings.json"

    // MARK: - StoreKit 2

    static let plusMonthlyID = "sorosoro.plus.monthly"
    static let plusYearlyID = "sorosoro.plus.yearly"
    static let allProductIDs: Set<String> = [plusMonthlyID, plusYearlyID]

    // MARK: - Notification

    static let notificationCategoryID = "SOROSORO_REMINDER"
    static let notificationActionPurchased = "PURCHASED"
    static let defaultNotificationHour = 9

    // MARK: - App Group

    static var sharedContainerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}
