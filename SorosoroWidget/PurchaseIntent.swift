import AppIntents
import WidgetKit

struct PurchaseItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark as Purchased"

    @Parameter(title: "Item ID")
    var itemId: String

    init() {}

    init(itemId: UUID) {
        self.itemId = itemId.uuidString
    }

    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: itemId) else { return .result() }
        WidgetDataProvider.markPurchased(itemId: id)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
