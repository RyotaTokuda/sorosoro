import SwiftUI

struct ShoppingListView: View {
    @Environment(ItemStore.self) private var itemStore
    @Environment(ShoppingListStore.self) private var shoppingListStore
    @Environment(PlanService.self) private var planService
    @Environment(SettingsStore.self) private var settingsStore
    @State private var showingAutoAdd = false

    var body: some View {
        List {
            // 自動追加候補
            let urgentItems = filteredUrgentItems
            if !urgentItems.isEmpty {
                Section("そろそろ買い時") {
                    ForEach(urgentItems) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.body)
                                Text(item.mode.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if shoppingListStore.hasEntry(for: item.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Button {
                                    shoppingListStore.addEntry(itemId: item.id)
                                } label: {
                                    Image(systemName: "plus.circle")
                                }
                            }
                        }
                    }
                }
            }

            // 買い物リスト
            let unchecked = shoppingListStore.uncheckedEntries
            if !unchecked.isEmpty {
                Section("買い物リスト") {
                    ForEach(unchecked) { entry in
                        if let item = itemStore.item(by: entry.itemId) {
                            ShoppingRowView(entry: entry, item: item)
                        }
                    }
                }
            }

            // チェック済み
            let checked = shoppingListStore.checkedEntries
            if !checked.isEmpty {
                Section {
                    ForEach(checked) { entry in
                        if let item = itemStore.item(by: entry.itemId) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text(item.name)
                                    .strikethrough()
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("購入済み")
                        Spacer()
                        Button("クリア") {
                            shoppingListStore.clearChecked()
                        }
                        .font(.caption)
                    }
                }
            }

            if urgentItems.isEmpty && unchecked.isEmpty && checked.isEmpty {
                ContentUnavailableView {
                    Label("買い物リストは空です", systemImage: "cart")
                } description: {
                    Text("交換時期が近づくとここに表示されます")
                }
            }
        }
        .navigationTitle("買い物リスト")
    }

    /// 無料: 選択モードのみ、Plus: 全モード
    private var filteredUrgentItems: [Item] {
        if planService.canCrossModeShopping() {
            return itemStore.urgentItems()
        } else {
            return itemStore.urgentItems(for: settingsStore.settings.selectedMode)
        }
    }
}

struct ShoppingRowView: View {
    let entry: ShoppingListEntry
    let item: Item
    @Environment(ItemStore.self) private var itemStore
    @Environment(ShoppingListStore.self) private var shoppingListStore
    @State private var showingConfirm = false

    var body: some View {
        HStack {
            Button {
                showingConfirm = true
            } label: {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading) {
                Text(item.name)
                Text(item.mode.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            statusBadge
        }
        .alert("購入完了", isPresented: $showingConfirm) {
            Button("キャンセル", role: .cancel) {}
            Button("買った！") {
                itemStore.markPurchased(id: item.id)
                if let updatedItem = itemStore.item(by: item.id) {
                    NotificationService.scheduleNotification(for: updatedItem)
                }
                shoppingListStore.checkEntry(id: entry.id)
            }
        } message: {
            Text("\(item.name)を購入済みにしますか？")
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch item.status {
        case .overdue:
            Text("\(abs(item.daysRemaining))日超過")
                .font(.caption2)
                .foregroundStyle(.red)
        case .soon:
            Text("あと\(item.daysRemaining)日")
                .font(.caption2)
                .foregroundStyle(.orange)
        case .ok:
            Text("あと\(item.daysRemaining)日")
                .font(.caption2)
                .foregroundStyle(.green)
        }
    }
}
