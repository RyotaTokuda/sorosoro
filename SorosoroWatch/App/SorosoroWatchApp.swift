import SwiftUI

@main
struct SorosoroWatchApp: App {
    @State private var itemStore = ItemStore()
    @State private var shoppingListStore = ShoppingListStore()
    @State private var settingsStore = SettingsStore()
    @State private var planService = PlanService()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environment(itemStore)
                .environment(shoppingListStore)
                .environment(settingsStore)
                .environment(planService)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        itemStore.reload()
                        shoppingListStore.reload()
                        Task { await planService.updatePurchaseStatus() }
                    }
                }
                .onAppear {
                    setupWatchSync()
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
        sync.onShoppingListChanged = { [itemStore, shoppingListStore] in
            itemStore.reload()
            shoppingListStore.reload()
        }
    }
}
