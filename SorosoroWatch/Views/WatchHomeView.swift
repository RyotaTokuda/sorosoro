import SwiftUI

struct WatchHomeView: View {
    @Environment(ItemStore.self) private var itemStore

    var body: some View {
        NavigationStack {
            List {
                let urgent = itemStore.urgentItems()
                if !urgent.isEmpty {
                    Section("watch.home.urgent.section") {
                        ForEach(urgent.prefix(5)) { item in
                            NavigationLink(destination: WatchItemDetailView(itemId: item.id)) {
                                WatchItemRow(item: item)
                            }
                        }
                    }
                }

                Section("watch.home.category.section") {
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

                NavigationLink(destination: WatchShoppingListView()) {
                    Label("watch.shopping.nav.title", systemImage: "cart.fill")
                }

                if urgent.isEmpty {
                    ContentUnavailableView {
                        Label("watch.home.all.ok.title", systemImage: "checkmark.circle")
                    } description: {
                        Text("watch.home.all.ok.description")
                    }
                }
            }
            .navigationTitle("watch.nav.title")
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
            Text("status.overdue \(abs(item.daysRemaining))")
                .font(.caption2)
                .foregroundStyle(.red)
        case .soon:
            Text("status.remaining \(item.daysRemaining)")
                .font(.caption2)
                .foregroundStyle(.orange)
        case .ok:
            Text("status.remaining \(item.daysRemaining)")
                .font(.caption2)
                .foregroundStyle(.green)
        }
    }
}
