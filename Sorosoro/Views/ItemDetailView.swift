import SwiftUI

struct ItemDetailView: View {
    let itemId: UUID
    @Environment(ItemStore.self) private var itemStore
    @Environment(ShoppingListStore.self) private var shoppingListStore
    @State private var showingEditSheet = false
    @State private var showingPurchaseConfirm = false
    @State private var suggestionDismissed = false

    private var item: Item? {
        itemStore.item(by: itemId)
    }

    var body: some View {
        if let item {
            List {
                // 周期最適化サジェスト
                if !suggestionDismissed, let suggested = item.suggestedCycleDays() {
                    cycleSuggestionSection(item: item, suggested: suggested)
                }

                // ステータスセクション
                Section {
                    HStack {
                        Text("ステータス")
                        Spacer()
                        statusText(item)
                    }
                    HStack {
                        Text("残り日数")
                        Spacer()
                        Text("\(item.daysRemaining)日")
                            .foregroundStyle(item.status == .overdue ? .red : .primary)
                    }
                    HStack {
                        Text("次回予定日")
                        Spacer()
                        Text(item.nextDueDate, style: .date)
                    }
                }

                // 詳細セクション
                Section("詳細") {
                    HStack {
                        Text("交換周期")
                        Spacer()
                        Text("\(item.cycleDays)日")
                    }
                    HStack {
                        Text("前回購入日")
                        Spacer()
                        Text(item.lastPurchaseDate, style: .date)
                    }
                    if !item.memo.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("メモ")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(item.memo)
                        }
                    }
                }

                // 購入履歴
                if !item.purchaseHistory.isEmpty {
                    Section("購入履歴 (直近\(item.purchaseHistory.count)回)") {
                        ForEach(item.purchaseHistory.sorted().reversed(), id: \.self) { date in
                            Text(date, style: .date)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // 通知セクション
                Section("通知") {
                    HStack {
                        Text("通知")
                        Spacer()
                        Text(item.notificationEnabled ? "ON" : "OFF")
                            .foregroundStyle(item.notificationEnabled ? .green : .secondary)
                    }
                    if item.notificationEnabled {
                        HStack {
                            Text("通知タイミング")
                            Spacer()
                            Text("\(item.notificationDaysBefore)日前")
                        }
                    }
                }

                // アクションセクション
                Section {
                    Button {
                        showingPurchaseConfirm = true
                    } label: {
                        Label("買った！", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .fontWeight(.semibold)
                    }

                    if !shoppingListStore.hasEntry(for: item.id) {
                        Button {
                            shoppingListStore.addEntry(itemId: item.id)
                        } label: {
                            Label("買い物リストに追加", systemImage: "cart.badge.plus")
                        }
                    }
                }
            }
            .navigationTitle(item.name)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("編集") { showingEditSheet = true }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                NavigationStack {
                    ItemFormView(mode: item.mode, editingItem: item)
                }
            }
            .alert("購入完了", isPresented: $showingPurchaseConfirm) {
                Button("キャンセル", role: .cancel) {}
                Button("買った！") {
                    itemStore.markPurchased(id: item.id)
                    if let updated = itemStore.item(by: item.id) {
                        NotificationService.scheduleNotification(for: updated)
                    }
                    shoppingListStore.removeEntries(for: item.id)
                    suggestionDismissed = false  // re-evaluate after new purchase
                }
            } message: {
                Text("\(item.name)を購入済みにしますか？\n次回予定日が更新されます。")
            }
        } else {
            ContentUnavailableView("アイテムが見つかりません", systemImage: "questionmark.circle")
        }
    }

    // MARK: - Suggestion Banner

    @ViewBuilder
    private func cycleSuggestionSection(item: Item, suggested: Int) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text("周期を最適化できます")
                        .font(.subheadline.bold())
                    Spacer()
                    Button {
                        suggestionDismissed = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text("\(item.purchaseHistory.count)回の購入実績から、実際の消費ペースは約**\(suggested)日**です。（現在の設定: \(item.cycleDays)日）")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button {
                        applysuggestion(to: item, days: suggested)
                    } label: {
                        Text("周期を\(suggested)日に変更")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    Button {
                        suggestionDismissed = true
                    } label: {
                        Text("このままにする")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(.secondary.opacity(0.15))
                            .foregroundStyle(.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
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
        if updated.notificationEnabled {
            NotificationService.scheduleNotification(for: updated)
        }
        suggestionDismissed = true
    }

    // MARK: - Helpers

    @ViewBuilder
    private func statusText(_ item: Item) -> some View {
        switch item.status {
        case .overdue:
            Text("期限切れ").foregroundStyle(.red).fontWeight(.semibold)
        case .soon:
            Text("そろそろ").foregroundStyle(.orange).fontWeight(.semibold)
        case .ok:
            Text("まだ大丈夫").foregroundStyle(.green)
        }
    }
}
