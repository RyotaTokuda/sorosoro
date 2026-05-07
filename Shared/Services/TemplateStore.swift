import Foundation
import CloudKit

@Observable
@MainActor
final class TemplateStore {

    private(set) var customTemplates: [ItemTemplate] = []

    private let ck = CloudKitService.shared
    private let cacheURL: URL = AppConstants.sharedContainerURL
        .appendingPathComponent(AppConstants.customTemplatesFileName)

    init() { loadCache() }

    // MARK: - Query

    func templates(for mode: Mode) -> [ItemTemplate] {
        let modes: [Mode] = mode == .daily ? [.daily, .gadget] : [mode]
        let custom = customTemplates.filter { modes.contains($0.mode) }
        return DefaultTemplates.templates(for: mode) + custom
    }

    // MARK: - Operations

    func addCustomTemplate(_ template: ItemTemplate) {
        var t = template
        t.isDefault = false
        customTemplates.append(t)
        saveCache()
        Task { await pushToCloudKit(t) }
    }

    func deleteCustomTemplate(id: UUID) {
        customTemplates.removeAll { $0.id == id }
        saveCache()
        Task { await deleteFromCloudKit(id: id) }
    }

    // MARK: - Sync

    func applyCloudKitChanges(_ changes: CloudKitService.ZoneChanges) {
        for record in changes.changed where record.recordType == ItemTemplate.ckRecordType {
            guard let tmpl = ItemTemplate.from(record) else { continue }
            if let idx = customTemplates.firstIndex(where: { $0.id == tmpl.id }) {
                customTemplates[idx] = tmpl
            } else {
                customTemplates.append(tmpl)
            }
        }
        for deletedID in changes.deleted {
            guard let uuid = UUID(uuidString: deletedID.recordName) else { continue }
            customTemplates.removeAll { $0.id == uuid }
        }
        saveCache()
    }

    // MARK: - CloudKit Push

    private func pushToCloudKit(_ template: ItemTemplate) async {
        guard ck.isAvailable else { return }
        let record = template.toCKRecord(zoneID: ck.zoneID)
        try? await ck.save([record])
    }

    private func deleteFromCloudKit(id: UUID) async {
        guard ck.isAvailable else { return }
        let rid = CKRecord.ID(recordName: id.uuidString, zoneID: ck.zoneID)
        try? await ck.delete([rid])
    }

    // MARK: - JSON Cache

    private func loadCache() {
        guard FileManager.default.fileExists(atPath: cacheURL.path),
              let data = try? Data(contentsOf: cacheURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        customTemplates = (try? decoder.decode([ItemTemplate].self, from: data)) ?? []
    }

    private func saveCache() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(customTemplates) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }

    func migrateFromJSONIfNeeded() async {
        let key = "ck_migration_done_templates"
        guard !UserDefaults.standard.bool(forKey: key), ck.isAvailable else { return }
        let records = customTemplates.map { $0.toCKRecord(zoneID: ck.zoneID) }
        if !records.isEmpty { try? await ck.save(records) }
        UserDefaults.standard.set(true, forKey: key)
    }
}
