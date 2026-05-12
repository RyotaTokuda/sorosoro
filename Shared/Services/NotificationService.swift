import UserNotifications

enum NotificationService {
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// 全アイテムの通知を再スケジュール
    static func rescheduleAll(items: [Item], limit: Int) {
        let center = UNUserNotificationCenter.current()
        // 既存のそろそろ通知を全削除
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.identifier.hasPrefix("sorosoro-") }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }

        // 通知対象を抽出（通知ON + 未来の通知日 を残日数が近い順で）
        let targets = items
            .filter { $0.notificationEnabled }
            .sorted { $0.daysRemaining < $1.daysRemaining }
            .prefix(min(limit, 64)) // iOS上限64件

        for item in targets {
            scheduleNotification(for: item)
        }
    }

    /// 個別アイテムの通知をスケジュール
    static func scheduleNotification(for item: Item) {
        let center = UNUserNotificationCenter.current()
        let identifier = "sorosoro-\(item.id.uuidString)"

        // 既存を削除
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard item.notificationEnabled else { return }

        // 通知日を計算（nextDueDate の notificationDaysBefore 日前の朝9時）
        guard let notifyDate = Calendar.current.date(
            byAdding: .day,
            value: -item.notificationDaysBefore,
            to: item.nextDueDate
        ) else { return }

        // 過去の日付なら即時通知はしない（次の「買った！」後に再スケジュール）
        let notifyComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: notifyDate
        )
        var triggerComponents = notifyComponents
        triggerComponents.hour = AppConstants.defaultNotificationHour
        triggerComponents.minute = 0

        // 過去のトリガーはスキップ
        if let triggerDate = Calendar.current.date(from: triggerComponents),
           triggerDate <= Date() {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.title \(item.name)")
        content.body = String(localized: "notification.body \(item.notificationDaysBefore)")
        content.sound = .default
        content.categoryIdentifier = AppConstants.notificationCategoryID

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    /// アイテム削除時に通知もキャンセル
    static func cancelNotification(for itemId: UUID) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: ["sorosoro-\(itemId.uuidString)"]
        )
    }

    /// 通知アクションのカテゴリ登録
    static func registerCategories() {
        let purchasedAction = UNNotificationAction(
            identifier: AppConstants.notificationActionPurchased,
            title: String(localized: "notification.action.purchased"),
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: AppConstants.notificationCategoryID,
            actions: [purchasedAction],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
