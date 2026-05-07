import SwiftUI

struct WatchItemDetailView: View {
    let itemId: UUID
    @Environment(ItemStore.self) private var itemStore
    @Environment(ShoppingListStore.self) private var shoppingListStore
    @State private var showingPurchaseConfirm = false

    private var item: Item? {
        itemStore.item(by: itemId)
    }

    var body: some View {
        if let item {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // ステータス
                    HStack {
                        statusIcon(item)
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.headline)
                            statusText(item)
                        }
                    }

                    Divider()

                    // 詳細
                    VStack(alignment: .leading, spacing: 6) {
                        detailRow("周期", value: "\(item.cycleDays)日")
                        detailRow("前回", value: item.lastPurchaseDate.formatted(date: .abbreviated, time: .omitted))
                        detailRow("次回", value: item.nextDueDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    .font(.caption)

                    Divider()

                    // 買った！ボタン
                    Button {
                        showingPurchaseConfirm = true
                    } label: {
                        Label("買った！", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding(.horizontal)
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .alert("購入完了", isPresented: $showingPurchaseConfirm) {
                Button("キャンセル", role: .cancel) {}
                Button("買った！") {
                    itemStore.markPurchased(id: item.id)
                    shoppingListStore.removeEntries(for: item.id)
                    WatchSyncService.shared.sendMarkPurchased(itemId: item.id)
                }
            } message: {
                Text("\(item.name)を購入済みにしますか？")
            }
        }
    }

    @ViewBuilder
    private func statusIcon(_ item: Item) -> some View {
        switch item.status {
        case .overdue:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.red)
        case .soon:
            Image(systemName: "clock.fill")
                .font(.title2)
                .foregroundStyle(.orange)
        case .ok:
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
        }
    }

    @ViewBuilder
    private func statusText(_ item: Item) -> some View {
        switch item.status {
        case .overdue:
            Text("\(abs(item.daysRemaining))日超過")
                .font(.caption)
                .foregroundStyle(.red)
        case .soon:
            Text("あと\(item.daysRemaining)日")
                .font(.caption)
                .foregroundStyle(.orange)
        case .ok:
            Text("あと\(item.daysRemaining)日")
                .font(.caption)
                .foregroundStyle(.green)
        }
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}
