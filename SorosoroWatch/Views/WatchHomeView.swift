import SwiftUI

struct WatchHomeView: View {
    @Environment(ItemStore.self) private var itemStore

    var body: some View {
        NavigationStack {
            List {
                // 緊急アイテム（期限切れ + そろそろ）
                let urgent = itemStore.urgentItems()
                if !urgent.isEmpty {
                    Section("そろそろ") {
                        ForEach(urgent.prefix(5)) { item in
                            NavigationLink(destination: WatchItemDetailView(itemId: item.id)) {
                                WatchItemRow(item: item)
                            }
                        }
                    }
                }

                // モード別一覧へのリンク
                Section("カテゴリ") {
                    ForEach(Mode.allCases) { mode in
                        let count = itemStore.itemCount(for: mode)
                        if count > 0 {
                            NavigationLink(destination: WatchItemListView(mode: mode)) {
                                Label {
                                    HStack {
                                        Text(mode.displayName)
                                        Spacer()
                                        Text("\(count)")
                                            .foregroundStyle(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: mode.iconName)
                                }
                            }
                        }
                    }
                }

                // 買い物リストへ
                NavigationLink(destination: WatchShoppingListView()) {
                    Label("買い物リスト", systemImage: "cart.fill")
                }

                if urgent.isEmpty {
                    ContentUnavailableView {
                        Label("全てOK", systemImage: "checkmark.circle")
                    } description: {
                        Text("そろそろなアイテムはありません")
                    }
                }
            }
            .navigationTitle("そろそろ")
        }
    }
}

struct WatchItemRow: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.name)
                .font(.body)
                .lineLimit(1)
            HStack {
                Image(systemName: item.mode.iconName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                statusText
            }
        }
    }

    @ViewBuilder
    private var statusText: some View {
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
