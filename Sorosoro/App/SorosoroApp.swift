import SwiftUI
import CloudKit

@main
struct SorosoroApp: App {
    let itemStore         = ItemStore()
    let shoppingListStore = ShoppingListStore()
    let templateStore     = TemplateStore()
    let settingsStore     = SettingsStore()
    let planService       = PlanService()
    let userProfileStore  = UserProfileStore()

    private let syncCoordinator: SyncCoordinator

    init() {
        syncCoordinator = SyncCoordinator(
            itemStore: itemStore,
            shoppingListStore: shoppingListStore,
            templateStore: templateStore
        )
    }

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(itemStore)
                .environment(shoppingListStore)
                .environment(templateStore)
                .environment(settingsStore)
                .environment(planService)
                .environment(userProfileStore)
                .task {
                    NotificationService.registerCategories()
                    await CloudKitService.shared.setup()
                    await itemStore.migrateFromJSONIfNeeded()
                    await shoppingListStore.migrateFromJSONIfNeeded()
                    await templateStore.migrateFromJSONIfNeeded()
                    await syncCoordinator.syncAll()
                }
                .onAppear {
                    setupWatchSync()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { await syncCoordinator.syncAll() }
                        Task { await planService.updatePurchaseStatus() }
                        if settingsStore.settings.globalNotificationEnabled {
                            NotificationService.rescheduleAll(
                                items: itemStore.items,
                                limit: planService.notificationLimit()
                            )
                        }
                    }
                }
                .onContinueUserActivity("com.apple.cloudkit.share") { activity in
                    guard let metadata = activity.userInfo?["NSCKShareMetadataKey"]
                            as? CKShare.Metadata else { return }
                    Task {
                        try? await CloudKitService.shared.acceptShare(metadata)
                        await syncCoordinator.syncAll()
                    }
                }
        }
    }

    private func setupWatchSync() {
        let sync = WatchSyncService.shared
        sync.activate()

        sync.onItemUpdated = { [itemStore] item in
            if itemStore.item(by: item.id) != nil {
                itemStore.updateItem(item)
            } else {
                itemStore.addItem(item)
            }
        }
        sync.onItemDeleted = { [itemStore, shoppingListStore] id in
            itemStore.deleteItem(id: id)
            shoppingListStore.removeEntries(for: id)
        }
        sync.onShoppingListChanged = { [syncCoordinator] in
            Task { await syncCoordinator.syncAll() }
        }
    }
}
