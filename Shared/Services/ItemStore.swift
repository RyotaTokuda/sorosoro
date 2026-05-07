import Foundation
import CloudKit

@Observable
@MainActor
final class ItemStore {

    private(set) var items: [Item] = []

    private let ck = CloudKitService.shared
    // JSON キャッシュ（オフライン時の読み取り用）
    private let cacheURL: URL = AppConstants.sharedContainerURL
        .appendingPathComponent(AppConstants.itemsFileName)
    // sharedDB から取得したアイテムの zone 情報（書き込み先判定用）
    private var sharedZoneIDs: [UUID: CKRecordZone.ID] = [:]

    init() {
        loadCache()  // キャッシュから即時ロード
    }

    // MARK: - Query

    func items(for mode: Mode) -> [Item] {
        items.filter { effectiveMode($0.mode) == mode }
            .sorted { $0.daysRemaining < $1.daysRemaining }
    }

    func item(by id: UUID) -> Item? {
        items.first { $0.id == id }
    }

    func urgentItems() -> [Item] {
        items.filter { $0.status != .ok }
            .sorted { $0.daysRemaining < $1.daysRemaining }
    }

    func urgentItems(for mode: Mode) -> [Item] {
        urgentItems().filter { effectiveMode($0.mode) == mode }
    }

    func itemCount(for mode: Mode) -> Int {
        items.filter { effectiveMode($0.mode) == mode }.count
    }

    // gadget is merged into daily — existing gadget items appear in the daily list
    private func effectiveMode(_ mode: Mode) -> Mode {
        mode == .gadget ? .daily : mode
    }

    // MARK: - CRUD

    func addItem(_ item: Item) {
        items.append(item)
        saveCache()
        Task { await pushToCloudKit(item) }
    }

    func updateItem(_ item: Item) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        var updated = item
        updated.updatedAt = Date()
        items[idx] = updated
        saveCache()
        Task { await pushToCloudKit(updated) }
    }

    func deleteItem(id: UUID) {
        items.removeAll { $0.id == id }
        saveCache()
        Task { await deleteFromCloudKit(id: id) }
    }

    func markPurchased(id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].markPurchased()
        saveCache()
        Task { await pushToCloudKit(items[idx]) }
    }

    // MARK: - Apply (called by SyncCoordinator)

    func applyPrivateChanges(_ changes: CloudKitService.ZoneChanges) {
        for record in changes.changed where record.recordType == Item.ckRecordType {
            guard let item = Item.from(record, isShared: false) else { continue }
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx] = item
            } else {
                items.append(item)
            }
        }
        for deletedID in changes.deleted {
            guard let uuid = UUID(uuidString: deletedID.recordName) else { continue }
            items.removeAll { $0.id == uuid }
            sharedZoneIDs.removeValue(forKey: uuid)
        }
        saveCache()
    }

    func applySharedRecords(_ records: [CKRecord]) {
        items.removeAll { $0.isShared }
        sharedZoneIDs.removeAll()
        for record in records where record.recordType == Item.ckRecordType {
            guard let item = Item.from(record, isShared: true) else { continue }
            items.append(item)
            sharedZoneIDs[item.id] = record.recordID.zoneID
        }
        saveCache()
    }

    // MARK: - CloudKit Push

    private func pushToCloudKit(_ item: Item) async {
        guard ck.isAvailable else { return }
        let zoneID = item.isShared
            ? (sharedZoneIDs[item.id] ?? ck.zoneID)
            : ck.zoneID
        let record = item.toCKRecord(zoneID: zoneID)
        let db = item.isShared ? ck.sharedDB : ck.privateDB
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
        guard FileManager.default.fileExists(atPath: cacheURL.path) else { return }
        guard let data = try? Data(contentsOf: cacheURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        items = (try? decoder.decode([Item].self, from: data)) ?? []
    }

    private func saveCache() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(items.filter { !$0.isShared }) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }

    // MARK: - JSON → CloudKit マイグレーション

    /// 既存 JSON データを CloudKit に移行（初回のみ）
    func migrateFromJSONIfNeeded() async {
        let migrationKey = "ck_migration_done_items"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }
        guard ck.isAvailable else { return }

        let records = items.map { $0.toCKRecord(zoneID: ck.zoneID) }
        try? await ck.save(records)
        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}
