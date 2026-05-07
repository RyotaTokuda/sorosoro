import Foundation
import CloudKit

@Observable
@MainActor
final class ShoppingListStore {

    private(set) var entries: [ShoppingListEntry] = []

    private let ck = CloudKitService.shared
    private let cacheURL: URL = AppConstants.sharedContainerURL
        .appendingPathComponent(AppConstants.shoppingListFileName)
    private var sharedZoneIDs: [UUID: CKRecordZone.ID] = [:]

    init() { loadCache() }

    // MARK: - Query

    var uncheckedEntries: [ShoppingListEntry] {
        entries.filter { !$0.isChecked }.sorted { $0.addedAt < $1.addedAt }
    }

    var checkedEntries: [ShoppingListEntry] {
        entries.filter { $0.isChecked }
            .sorted { ($0.checkedAt ?? $0.addedAt) > ($1.checkedAt ?? $1.addedAt) }
    }

    func hasEntry(for itemId: UUID) -> Bool {
        entries.contains { $0.itemId == itemId && !$0.isChecked }
    }

    // MARK: - Operations

    func addEntry(itemId: UUID) {
        guard !hasEntry(for: itemId) else { return }
        let entry = ShoppingListEntry(itemId: itemId)
        entries.append(entry)
        saveCache()
        Task { await pushToCloudKit(entry) }
    }

    func checkEntry(id: UUID) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].isChecked = true
        entries[idx].checkedAt = Date()
        saveCache()
        Task { await pushToCloudKit(entries[idx]) }
    }

    func removeEntry(id: UUID) {
        entries.removeAll { $0.id == id }
        saveCache()
        Task { await deleteFromCloudKit(id: id) }
    }

    func clearChecked() {
        let toDelete = entries.filter { $0.isChecked }.map { $0.id }
        entries.removeAll { $0.isChecked }
        saveCache()
        Task {
            for id in toDelete { await deleteFromCloudKit(id: id) }
        }
    }

    func removeEntries(for itemId: UUID) {
        let toDelete = entries.filter { $0.itemId == itemId }.map { $0.id }
        entries.removeAll { $0.itemId == itemId }
        saveCache()
        Task {
            for id in toDelete { await deleteFromCloudKit(id: id) }
        }
    }

    // MARK: - Apply (called by SyncCoordinator)

    func applyPrivateChanges(_ changes: CloudKitService.ZoneChanges) {
        for record in changes.changed where record.recordType == ShoppingListEntry.ckRecordType {
            guard let entry = ShoppingListEntry.from(record, isShared: false) else { continue }
            if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[idx] = entry
            } else {
                entries.append(entry)
            }
        }
        for deletedID in changes.deleted {
            guard let uuid = UUID(uuidString: deletedID.recordName) else { continue }
            entries.removeAll { $0.id == uuid }
        }
        saveCache()
    }

    func applySharedRecords(_ records: [CKRecord]) {
        entries.removeAll { $0.isShared }
        sharedZoneIDs.removeAll()
        for record in records where record.recordType == ShoppingListEntry.ckRecordType {
            guard let entry = ShoppingListEntry.from(record, isShared: true) else { continue }
            entries.append(entry)
            sharedZoneIDs[entry.id] = record.recordID.zoneID
        }
        saveCache()
    }

    // MARK: - CloudKit Push

    private func pushToCloudKit(_ entry: ShoppingListEntry) async {
        guard ck.isAvailable else { return }
        let zoneID = entry.isShared ? (sharedZoneIDs[entry.id] ?? ck.zoneID) : ck.zoneID
        let record = entry.toCKRecord(zoneID: zoneID)
        let db = entry.isShared ? ck.sharedDB : ck.privateDB
        try? await ck.save([record], to: db)
    }

    private func deleteFromCloudKit(id: UUID) async {
        guard ck.isAvailable else { return }
        let zoneID = sharedZoneIDs[id] ?? ck.zoneID
        let rid = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        let db = sharedZoneIDs[id] != nil ? ck.sharedDB : ck.privateDB
        try? await ck.delete([rid], from: db)
        sharedZoneIDs.removeValue(forKey: id)
    }

    // MARK: - JSON Cache

    func reload() { loadCache() }

    private func loadCache() {
        guard FileManager.default.fileExists(atPath: cacheURL.path),
              let data = try? Data(contentsOf: cacheURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        entries = (try? decoder.decode([ShoppingListEntry].self, from: data)) ?? []
    }

    func saveCache() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(entries.filter { !$0.isShared }) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }

    func migrateFromJSONIfNeeded() async {
        let key = "ck_migration_done_shopping"
        guard !UserDefaults.standard.bool(forKey: key), ck.isAvailable else { return }
        let records = entries.map { $0.toCKRecord(zoneID: ck.zoneID) }
        try? await ck.save(records)
        UserDefaults.standard.set(true, forKey: key)
    }
}
