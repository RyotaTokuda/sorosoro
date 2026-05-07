import Foundation

struct ShoppingListEntry: Codable, Identifiable {
    private enum CodingKeys: String, CodingKey {
        case id, itemId, addedAt, isChecked, checkedAt
    }

    var id: UUID
    var itemId: UUID
    var addedAt: Date
    var isChecked: Bool
    var checkedAt: Date?
    var isShared: Bool = false

    init(id: UUID = UUID(), itemId: UUID) {
        self.id = id
        self.itemId = itemId
        self.addedAt = Date()
        self.isChecked = false
        self.checkedAt = nil
    }
}
