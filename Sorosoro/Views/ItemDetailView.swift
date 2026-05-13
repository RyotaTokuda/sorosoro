import SwiftUI

struct ItemDetailView: View {
    let itemId: UUID
    @Environment(ItemStore.self) private var itemStore
    @Environment(ShoppingListStore.self) private var shoppingListStore
    @Environment(PlanService.self) private var planService
    @State private var showingPurchaseConfirm = false
    @State private var suggestionDismissed = false

    private var item: Item? { itemStore.item(by: itemId) }

    private static let cycleDayOptions = [7, 14, 21, 30, 45, 60, 90, 120, 180, 270, 365, 545, 730, 1095]
    private static let notifDayOptions = [1, 2, 3, 5, 7, 10, 14]

    private func cycleDaysLabel(_ days: Int) -> String {
        switch days {
        case 7: return "7日（1週間）"
        case 14: return "14日（2週間）"
        case 21: return "21日（3週間）"
        case 30: return "30日（約1ヶ月）"
        case 45: return "45日（約1.5ヶ月）"
        case 60: return "60日（約2ヶ月）"
        case 90: return "90日（約3ヶ月）"
        case 120: return "120日（約4ヶ月）"
        case 180: return "180日（半年）"
        case 270: return "270日（約9ヶ月）"
        case 365: return "365日（1年）"
        case 545: return "545日（約1.5年）"
        case 730: return "730日（2年）"
        case 1095: return "1095日（3年）"
        default: return "\(days)日"
        }
    }

    private func cycleDayOptions(current: Int) -> [Int] {
        let s = Self.cycleDayOptions
        return s.contains(current) ? s : (s + [current]).sorted()
    }

    var body: some View {
        if let item {
            List {
                if !suggestionDismissed, let suggested = item.suggestedCycleDays() {
                    cycleSuggestionSection(item: item, suggested: suggested)
                }

                // ── ステータス ──
                Section {
                    HStack {
                        Text("item.detail.status")
                        Spacer()
                        statusText(item)
                    }
                    HStack {
                        Text("item.detail.days.remaining")
                        Spacer()
                        Text("item.detail.days.value \(item.daysRemaining)")
                            .foregroundStyle(item.status == .overdue ? .red : .primary)
                    }
                    HStack {
                        Text("item.detail.next.due.date")
                        Spacer()
                        Text(item.nextDueDate, style: .date)
                    }
                }

                // ── 編集可能フィールド ──
                Section("item.detail.section.detail") {
                    // 交換周期
                    Picker("item.detail.cycle", selection: cycleDaysBinding(item)) {
                        ForEach(cycleDayOptions(current: item.cycleDays), id: \.self) { d in
                            Text(cycleDaysLabel(d)).tag(d)
                        }
                    }

                    // 前回購入日
                    DatePicker(
                        String(localized: "item.detail.last.purchase"),
                        selection: lastPurchaseDateBinding(item),
                        displayedComponents: .date
                    )

                    // メモ
                    if planService.canUseMemo() {
                        TextField(
                            String(localized: "form.memo.placeholder"),
                            text: memoBinding(item),
                            axis: .vertical
                        )
                        .lineLimit(2...5)
                        .foregroundStyle(.primary)
                    } else if !item.memo.isEmpty {
                        Text(item.memo)
                            .foregroundStyle(.secondary)
                    }
                }

                // ── 通知設定 ──
                Section("item.detail.section.notification") {
                    Toggle("form.notification.toggle", isOn: notifEnabledBinding(item))

                    if item.notificationEnabled {
                        Picker("item.detail.notification.timing", selection: notifDaysBinding(item)) {
                            ForEach(Self.notifDayOptions, id: \.self) { d in
                                Text("item.detail.notification.days.before \(d)").tag(d)
                            }
                        }
                    }
                }

                // ── 購入履歴 ──
                if !item.purchaseHistory.isEmpty {
                    Section("item.detail.history.title \(item.purchaseHistory.count)") {
                        ForEach(item.purchaseHistory.sorted().reversed(), id: \.self) { date in
                            Text(date, style: .date)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // ── アクション ──
                Section {
                    Button {
                        showingPurchaseConfirm = true
                    } label: {
                        Label("action.purchased", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .fontWeight(.semibold)
                    }

                    if !shoppingListStore.hasEntry(for: item.id) {
                        Button {
                            shoppingListStore.addEntry(itemId: item.id)
                        } label: {
                            Label("action.add.to.shopping", systemImage: "cart.badge.plus")
                        }
                    }
                }
            }
            .navigationTitle(item.name)
            .alert("alert.purchase.complete.title", isPresented: $showingPurchaseConfirm) {
                Button("common.cancel", role: .cancel) {}
                Button("action.purchased") {
                    itemStore.markPurchased(id: item.id)
                    if let updated = itemStore.item(by: item.id) {
                        NotificationService.scheduleNotification(for: updated)
                    }
                    shoppingListStore.removeEntries(for: item.id)
                    suggestionDismissed = false
                }
            } message: {
                Text("alert.purchase.confirm.message \(item.name)")
            }
        } else {
            ContentUnavailableView("item.detail.not.found", systemImage: "questionmark.circle")
        }
    }

    // MARK: - Bindings

    private func cycleDaysBinding(_ item: Item) -> Binding<Int> {
        Binding(
            get: { item.cycleDays },
            set: { newValue in
                var updated = item
                updated.cycleDays = newValue
                updated.nextDueDate = Calendar.current.date(
                    byAdding: .day, value: newValue, to: updated.lastPurchaseDate
                ) ?? updated.lastPurchaseDate
                updated.updatedAt = Date()
                itemStore.updateItem(updated)
                if updated.notificationEnabled {
                    NotificationService.scheduleNotification(for: updated)
                }
            }
        )
    }

    private func lastPurchaseDateBinding(_ item: Item) -> Binding<Date> {
        Binding(
            get: { item.lastPurchaseDate },
            set: { newValue in
                var updated = item
                updated.lastPurchaseDate = newValue
                updated.nextDueDate = Calendar.current.date(
                    byAdding: .day, value: updated.cycleDays, to: newValue
                ) ?? newValue
                updated.updatedAt = Date()
                itemStore.updateItem(updated)
                if updated.notificationEnabled {
                    NotificationService.scheduleNotification(for: updated)
                }
            }
        )
    }

    private func memoBinding(_ item: Item) -> Binding<String> {
        Binding(
            get: { item.memo },
            set: { newValue in
                var updated = item
                updated.memo = newValue
                updated.updatedAt = Date()
                itemStore.updateItem(updated)
            }
        )
    }

    private func notifEnabledBinding(_ item: Item) -> Binding<Bool> {
        Binding(
            get: { item.notificationEnabled },
            set: { newValue in
                var updated = item
                updated.notificationEnabled = newValue
                updated.updatedAt = Date()
                itemStore.updateItem(updated)
                if newValue {
                    Task {
                        _ = await NotificationService.requestPermission()
                        NotificationService.scheduleNotification(for: updated)
                    }
                } else {
                    NotificationService.cancelNotification(for: updated.id)
                }
            }
        )
    }

    private func notifDaysBinding(_ item: Item) -> Binding<Int> {
        Binding(
            get: { item.notificationDaysBefore },
            set: { newValue in
                var updated = item
                updated.notificationDaysBefore = newValue
                updated.updatedAt = Date()
                itemStore.updateItem(updated)
                if updated.notificationEnabled {
                    NotificationService.scheduleNotification(for: updated)
                }
            }
        )
    }

    // MARK: - Suggestion Banner

    @ViewBuilder
    private func cycleSuggestionSection(item: Item, suggested: Int) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "lightbulb.fill").foregroundStyle(.yellow)
                    Text("suggestion.title").font(.subheadline.bold())
                    Spacer()
                    Button { suggestionDismissed = true } label: {
                        Image(systemName: "xmark").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Text("suggestion.body \(item.purchaseHistory.count) \(suggested) \(item.cycleDays)")
                    .font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Button {
                        applysuggestion(to: item, days: suggested)
                    } label: {
                        Text("suggestion.apply \(suggested)")
                            .font(.caption.bold()).frame(maxWidth: .infinity)
                            .padding(.vertical, 8).background(.blue)
                            .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    Button { suggestionDismissed = true } label: {
                        Text("suggestion.dismiss")
                            .font(.caption).frame(maxWidth: .infinity)
                            .padding(.vertical, 8).background(.secondary.opacity(0.15))
                            .foregroundStyle(.secondary).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func applysuggestion(to item: Item, days: Int) {
        var updated = item
        updated.cycleDays = days
        updated.nextDueDate = Calendar.current.date(
            byAdding: .day, value: days, to: updated.lastPurchaseDate
        ) ?? updated.lastPurchaseDate
        updated.updatedAt = Date()
        itemStore.updateItem(updated)
        if updated.notificationEnabled { NotificationService.scheduleNotification(for: updated) }
        suggestionDismissed = true
    }

    @ViewBuilder
    private func statusText(_ item: Item) -> some View {
        switch item.status {
        case .overdue: Text("status.overdue.label").foregroundStyle(.red).fontWeight(.semibold)
        case .soon:    Text("status.soon.label").foregroundStyle(.orange).fontWeight(.semibold)
        case .ok:      Text("status.ok.label").foregroundStyle(.green)
        }
    }
}
