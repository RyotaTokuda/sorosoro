import Foundation

struct Item: Codable, Identifiable {
    private enum CodingKeys: String, CodingKey {
        case id, name, mode, cycleDays, lastPurchaseDate, nextDueDate
        case memo, notificationEnabled, notificationDaysBefore
        case createdAt, updatedAt, purchaseHistory
    }
    var id: UUID
    var name: String
    var mode: Mode
    var cycleDays: Int
    var lastPurchaseDate: Date
    var nextDueDate: Date
    var memo: String
    var notificationEnabled: Bool
    var notificationDaysBefore: Int
    var createdAt: Date
    var updatedAt: Date
    /// 購入履歴（markPurchased のたびに追記、最大 20 件保持）
    var purchaseHistory: [Date] = []
    /// CloudKit の sharedDB から取得したアイテムかどうか（永続化しない）
    var isShared: Bool = false

    init(
        id: UUID = UUID(),
        name: String,
        mode: Mode,
        cycleDays: Int,
        lastPurchaseDate: Date = Date(),
        memo: String = "",
        notificationEnabled: Bool = true,
        notificationDaysBefore: Int = 3
    ) {
        self.id = id
        self.name = name
        self.mode = mode
        self.cycleDays = cycleDays
        self.lastPurchaseDate = lastPurchaseDate
        self.nextDueDate = Calendar.current.date(byAdding: .day, value: cycleDays, to: lastPurchaseDate) ?? lastPurchaseDate
        self.memo = memo
        self.notificationEnabled = notificationEnabled
        self.notificationDaysBefore = notificationDaysBefore
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Derived

    var daysRemaining: Int {
        Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: nextDueDate)
        ).day ?? 0
    }

    var status: ItemStatus {
        if daysRemaining < 0        { return .overdue }
        if daysRemaining <= notificationDaysBefore { return .soon }
        return .ok
    }

    // MARK: - 「買った！」

    mutating func markPurchased() {
        let now = Date()
        purchaseHistory.append(now)
        if purchaseHistory.count > 20 {
            purchaseHistory.removeFirst(purchaseHistory.count - 20)
        }
        lastPurchaseDate = now
        nextDueDate = Calendar.current.date(byAdding: .day, value: cycleDays, to: now) ?? now
        updatedAt = now
    }

    // MARK: - 購入周期の自動最適化

    /// 購入履歴から推定される最適な周期（3 回以上の履歴が必要）
    /// 現在の cycleDays と 5 日以上差がある場合のみ値を返す
    func suggestedCycleDays() -> Int? {
        guard purchaseHistory.count >= 3 else { return nil }
        let sorted = purchaseHistory.sorted()
        var intervals: [Int] = []
        for i in 1..<sorted.count {
            let diff = Calendar.current.dateComponents([.day], from: sorted[i-1], to: sorted[i]).day ?? 0
            if diff > 0 { intervals.append(diff) }
        }
        guard intervals.count >= 2 else { return nil }
        let avg = intervals.reduce(0, +) / intervals.count
        guard avg > 0, abs(avg - cycleDays) >= 5 else { return nil }
        return avg
    }
}

enum ItemStatus {
    case overdue
    case soon
    case ok
}
