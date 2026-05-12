import Foundation

enum WidgetDataProvider {

    // MARK: - Load

    static func loadItems() -> [Item] {
        guard let data = try? Data(contentsOf: itemsURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Item].self, from: data)) ?? []
    }

    // MARK: - Mark purchased (writes back to App Group JSON)

    static func markPurchased(itemId: UUID) {
        guard var items = optionalItems() else { return }
        guard let idx = items.firstIndex(where: { $0.id == itemId }) else { return }
        items[idx].markPurchased()
        save(items)
    }

    // MARK: - Derived queries

    static func urgentItems(from items: [Item], limit: Int = 5) -> [Item] {
        items
            .filter { $0.status == .overdue || $0.status == .soon }
            .sorted { $0.daysRemaining < $1.daysRemaining }
            .prefix(limit)
            .map { $0 }
    }

    static func recentPurchases(from items: [Item], limit: Int = 3) -> [Item] {
        items
            .sorted { $0.lastPurchaseDate > $1.lastPurchaseDate }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Private helpers

    private static var itemsURL: URL {
        AppConstants.sharedContainerURL.appendingPathComponent(AppConstants.itemsFileName)
    }

    private static func optionalItems() -> [Item]? {
        guard let data = try? Data(contentsOf: itemsURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode([Item].self, from: data)
    }

    private static func save(_ items: [Item]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: itemsURL, options: .atomic)
    }
}
