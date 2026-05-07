import CloudKit
import Foundation

// MARK: - Item ↔ CKRecord

extension Item {
    static let ckRecordType = "Item"

    static func from(_ record: CKRecord, isShared: Bool = false) -> Item? {
        guard
            let idStr   = record["id"]   as? String, let id = UUID(uuidString: idStr),
            let name    = record["name"] as? String,
            let modeStr = record["mode"] as? String, let mode = Mode(rawValue: modeStr),
            let cycleDays          = record["cycleDays"]          as? Int64,
            let lastPurchaseDate   = record["lastPurchaseDate"]   as? Date,
            let nextDueDate        = record["nextDueDate"]        as? Date,
            let notifEnabled       = record["notificationEnabled"] as? Int64,
            let notifDaysBefore    = record["notificationDaysBefore"] as? Int64,
            let createdAt          = record["createdAt"]          as? Date,
            let updatedAt          = record["updatedAt"]          as? Date
        else { return nil }

        var item = Item(
            id: id,
            name: name,
            mode: mode,
            cycleDays: Int(cycleDays),
            lastPurchaseDate: lastPurchaseDate,
            memo: record["memo"] as? String ?? "",
            notificationEnabled: notifEnabled != 0,
            notificationDaysBefore: Int(notifDaysBefore)
        )
        item.nextDueDate     = nextDueDate
        item.createdAt       = createdAt
        item.updatedAt       = updatedAt
        item.isShared        = isShared
        item.purchaseHistory = (record["purchaseHistory"] as? [Date]) ?? []
        return item
    }

    func toCKRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let rid    = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: Item.ckRecordType, recordID: rid)
        record["id"]                    = id.uuidString
        record["name"]                  = name
        record["mode"]                  = mode.rawValue
        record["cycleDays"]             = Int64(cycleDays)
        record["lastPurchaseDate"]      = lastPurchaseDate
        record["nextDueDate"]           = nextDueDate
        record["memo"]                  = memo
        record["notificationEnabled"]   = Int64(notificationEnabled ? 1 : 0)
        record["notificationDaysBefore"] = Int64(notificationDaysBefore)
        record["createdAt"]             = createdAt
        record["updatedAt"]             = updatedAt
        if !purchaseHistory.isEmpty {
            record["purchaseHistory"]   = purchaseHistory as NSArray
        }
        return record
    }

    /// 共有 DB への書き込み用（zone owner の zoneID を使う）
    func toCKRecord(in shareZoneID: CKRecordZone.ID) -> CKRecord {
        toCKRecord(zoneID: shareZoneID)
    }
}

// MARK: - ShoppingListEntry ↔ CKRecord

extension ShoppingListEntry {
    static let ckRecordType = "ShoppingListEntry"

    static func from(_ record: CKRecord, isShared: Bool = false) -> ShoppingListEntry? {
        guard
            let idStr    = record["id"]     as? String, let id = UUID(uuidString: idStr),
            let itemStr  = record["itemId"] as? String, let itemId = UUID(uuidString: itemStr),
            let addedAt  = record["addedAt"] as? Date,
            let isChecked = record["isChecked"] as? Int64
        else { return nil }

        var entry = ShoppingListEntry(id: id, itemId: itemId)
        entry.addedAt  = addedAt
        entry.isChecked = isChecked != 0
        entry.checkedAt = record["checkedAt"] as? Date
        entry.isShared  = isShared
        return entry
    }

    func toCKRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let rid    = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: ShoppingListEntry.ckRecordType, recordID: rid)
        record["id"]        = id.uuidString
        record["itemId"]    = itemId.uuidString
        record["addedAt"]   = addedAt
        record["isChecked"] = Int64(isChecked ? 1 : 0)
        record["checkedAt"] = checkedAt
        return record
    }
}

// MARK: - ItemTemplate ↔ CKRecord（カスタムテンプレートのみ）

extension ItemTemplate {
    static let ckRecordType = "CustomTemplate"

    static func from(_ record: CKRecord) -> ItemTemplate? {
        guard
            let idStr    = record["id"]   as? String, let id = UUID(uuidString: idStr),
            let name     = record["name"] as? String,
            let modeStr  = record["mode"] as? String, let mode = Mode(rawValue: modeStr),
            let cycleDays = record["cycleDays"] as? Int64,
            let notifDays = record["notificationDaysBefore"] as? Int64
        else { return nil }

        var tmpl = ItemTemplate(
            id: id,
            name: name,
            mode: mode,
            cycleDays: Int(cycleDays),
            notificationDaysBefore: Int(notifDays),
            isDefault: false
        )
        if let kmBase = record["distanceKmBase"] as? Int64 { tmpl.distanceKmBase = Int(kmBase) }
        return tmpl
    }

    func toCKRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let rid    = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: ItemTemplate.ckRecordType, recordID: rid)
        record["id"]                      = id.uuidString
        record["name"]                    = name
        record["mode"]                    = mode.rawValue
        record["cycleDays"]               = Int64(cycleDays)
        record["notificationDaysBefore"]  = Int64(notificationDaysBefore)
        if let kmBase = distanceKmBase { record["distanceKmBase"] = Int64(kmBase) }
        return record
    }
}
