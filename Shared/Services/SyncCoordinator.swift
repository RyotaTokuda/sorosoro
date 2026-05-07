import Foundation
import CloudKit

// MARK: - SyncCoordinator
// Single entry point for all CloudKit sync. Fetches once and distributes to all stores.

@Observable
@MainActor
final class SyncCoordinator {

    private(set) var isSyncing = false

    private let itemStore: ItemStore
    private let shoppingListStore: ShoppingListStore
    private let templateStore: TemplateStore
    private let ck = CloudKitService.shared

    init(itemStore: ItemStore, shoppingListStore: ShoppingListStore, templateStore: TemplateStore) {
        self.itemStore = itemStore
        self.shoppingListStore = shoppingListStore
        self.templateStore = templateStore
    }

    func syncAll() async {
        guard ck.isAvailable, !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            // Fetch private DB delta changes once
            let changes = try await ck.fetchPrivateChanges()
            itemStore.applyPrivateChanges(changes)
            shoppingListStore.applyPrivateChanges(changes)
            templateStore.applyCloudKitChanges(changes)

            // Fetch all records visible in shared DB (other users' shared zones)
            let sharedRecords = (try? await ck.fetchAllShared()) ?? []
            itemStore.applySharedRecords(sharedRecords)
            shoppingListStore.applySharedRecords(sharedRecords)
        } catch {
            print("[Sync] failed: \(error)")
        }
    }
}
