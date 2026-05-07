import CloudKit
import Foundation

// MARK: - Sync State

enum SyncState: Equatable {
    case idle
    case syncing
    case error(String)
}

// MARK: - CloudKitService

@Observable
@MainActor
final class CloudKitService {

    static let shared = CloudKitService()

    // CloudKit 基盤
    private let container = CKContainer(identifier: "iCloud.com.mankai.sorosoro")
    var privateDB: CKDatabase { container.privateCloudDatabase }
    var sharedDB:  CKDatabase { container.sharedCloudDatabase }

    let zoneID = CKRecordZone.ID(
        zoneName: "SorosoroData",
        ownerName: CKCurrentUserDefaultName
    )

    // 公開状態
    private(set) var isAvailable = false
    private(set) var syncState: SyncState = .idle

    // デルタ同期トークン（UserDefaults 永続化）
    var privateChangeToken: CKServerChangeToken? {
        get { loadToken("ck_private_token") }
        set { saveToken(newValue, "ck_private_token") }
    }

    private init() {}

    // MARK: - セットアップ

    func setup() async {
        do {
            let status = try await container.accountStatus()
            isAvailable = status == .available
            guard isAvailable else { return }
            try await createZoneIfNeeded()
            await setupSubscription()
        } catch {
            isAvailable = false
        }
    }

    private func createZoneIfNeeded() async throws {
        let zone = CKRecordZone(zoneID: zoneID)
        _ = try await privateDB.save(zone)
    }

    private func setupSubscription() async {
        await ensureSubscription(db: privateDB, id: "sorosoro-private-sub")
        await ensureSubscription(db: sharedDB,  id: "sorosoro-shared-sub")
    }

    private func ensureSubscription(db: CKDatabase, id: String) async {
        if (try? await db.subscription(for: id)) != nil { return }
        let sub = CKDatabaseSubscription(subscriptionID: id)
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        sub.notificationInfo = info
        try? await db.save(sub)
    }

    // MARK: - デルタ同期（private DB）

    struct ZoneChanges {
        var changed: [CKRecord] = []
        var deleted: [CKRecord.ID] = []
        var newToken: CKServerChangeToken?
    }

    func fetchPrivateChanges() async throws -> ZoneChanges {
        var result = ZoneChanges()

        let config = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        config.previousServerChangeToken = privateChangeToken

        let op = CKFetchRecordZoneChangesOperation(
            recordZoneIDs: [zoneID],
            configurationsByRecordZoneID: [zoneID: config]
        )

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            op.recordWasChangedBlock = { _, res in
                if case .success(let r) = res { result.changed.append(r) }
            }
            op.recordWithIDWasDeletedBlock = { id, _ in
                result.deleted.append(id)
            }
            op.recordZoneChangeTokensUpdatedBlock = { _, token, _ in
                result.newToken = token
            }
            op.fetchRecordZoneChangesResultBlock = { res in
                switch res {
                case .success: cont.resume()
                case .failure(let e): cont.resume(throwing: e)
                }
            }
            privateDB.add(op)
        }

        if let token = result.newToken { privateChangeToken = token }
        return result
    }

    // MARK: - 共有 DB 全取得

    func fetchAllShared() async throws -> [CKRecord] {
        var records: [CKRecord] = []
        let zones = try await sharedDB.allRecordZones()
        for zone in zones {
            for type in SorosoroRecordType.all {
                let query = CKQuery(recordType: type, predicate: NSPredicate(value: true))
                if let (results, _) = try? await sharedDB.records(matching: query, inZoneWith: zone.zoneID) {
                    for (_, res) in results {
                        if case .success(let r) = res { records.append(r) }
                    }
                }
            }
        }
        return records
    }

    // MARK: - 書き込み

    func save(_ records: [CKRecord], to db: CKDatabase? = nil) async throws {
        guard !records.isEmpty else { return }
        let database = db ?? privateDB
        let op = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        op.savePolicy = .changedKeys
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            op.modifyRecordsResultBlock = { res in
                switch res {
                case .success: cont.resume()
                case .failure(let e): cont.resume(throwing: e)
                }
            }
            database.add(op)
        }
    }

    func delete(_ ids: [CKRecord.ID], from db: CKDatabase? = nil) async throws {
        guard !ids.isEmpty else { return }
        let database = db ?? privateDB
        let op = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: ids)
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            op.modifyRecordsResultBlock = { res in
                switch res {
                case .success: cont.resume()
                case .failure(let e): cont.resume(throwing: e)
                }
            }
            database.add(op)
        }
    }

    // MARK: - 共有管理

    /// 既存の CKShare を取得、なければ作成
    func fetchOrCreateShare() async throws -> (CKShare, CKContainer) {
        // 既存の share を検索
        if let existing = try? await fetchExistingShare() {
            return (existing, container)
        }

        // zone-level share を作成
        let share = CKShare(recordZoneID: zoneID)
        share[CKShare.SystemFieldKey.title] = "そろそろ - 消耗品リスト"
        share.publicPermission = .none

        let op = CKModifyRecordsOperation(recordsToSave: [share], recordIDsToDelete: nil)
        op.savePolicy = .allKeys

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            op.modifyRecordsResultBlock = { res in
                switch res {
                case .success: cont.resume()
                case .failure(let e): cont.resume(throwing: e)
                }
            }
            privateDB.add(op)
        }

        return (share, container)
    }

    private func fetchExistingShare() async throws -> CKShare? {
        let query = CKQuery(recordType: "cloudkit.share", predicate: NSPredicate(value: true))
        let (results, _) = try await privateDB.records(matching: query, inZoneWith: zoneID)
        for (_, res) in results {
            if case .success(let r) = res, let share = r as? CKShare { return share }
        }
        return nil
    }

    func acceptShare(_ metadata: CKShare.Metadata) async throws {
        try await container.accept(metadata)
    }

    // MARK: - Token Helpers

    private func loadToken(_ key: String) -> CKServerChangeToken? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
    }

    private func saveToken(_ token: CKServerChangeToken?, _ key: String) {
        guard let token,
              let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
        else { UserDefaults.standard.removeObject(forKey: key); return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

// MARK: - Helpers

enum SorosoroRecordType {
    static let all: [String] = ["Item", "ShoppingListEntry", "CustomTemplate"]
}
