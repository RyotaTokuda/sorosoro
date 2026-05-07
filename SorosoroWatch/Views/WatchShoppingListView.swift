import SwiftUI

struct WatchShoppingListView: View {
    @Environment(ItemStore.self) private var itemStore
    @Environment(ShoppingListStore.self) private var shoppingListStore

    var body: some View {
        List {
            let unchecked = shoppingListStore.uncheckedEntries
            if !unchecked.isEmpty {
                ForEach(unchecked) { entry in
                    if let item = itemStore.item(by: entry.itemId) {
                        WatchShoppingRow(entry: entry, item: item)
                    }
                }
            }

            // そろそろ買い時（リストに未追加のもの）
            let urgent = itemStore.urgentItems().filter { item in
                !shoppingListStore.hasEntry(for: item.id)
            }
            if !urgent.isEmpty {
                Section("追加候補") {
                    ForEach(urgent.prefix(5)) { item in
                        Button {
                            shoppingListStore.addEntry(itemId: item.id)
                        } label: {
                            HStack {
                                Text(item.name)
                                    .font(.body)
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }

            if unchecked.isEmpty && urgent.isEmpty {
                Text("買い物リストは空です")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("買い物リスト")
    }
}

struct WatchShoppingRow: View {
    let entry: ShoppingListEntry
    let item: Item
    @Environment(ItemStore.self) private var itemStore
    @Environment(ShoppingListStore.self) private var shoppingListStore
    @State private var showingConfirm = false

    var body: some View {
        Button {
            showingConfirm = true
        } label: {
            HStack {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
                Text(item.name)
                    .font(.body)
            }
        }
        .alert("購入完了", isPresented: $showingConfirm) {
            Button("キャンセル", role: .cancel) {}
            Button("買った！") {
                itemStore.markPurchased(id: item.id)
                shoppingListStore.checkEntry(id: entry.id)
                WatchSyncService.shared.sendMarkPurchased(itemId: item.id)
            }
        } message: {
            Text("\(item.name)を購入済みに？")
        }
    }
}
