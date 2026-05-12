import SwiftUI

struct WatchItemListView: View {
    let mode: Mode
    @Environment(ItemStore.self) private var itemStore

    var body: some View {
        List {
            ForEach(itemStore.items(for: mode)) { item in
                NavigationLink(destination: WatchItemDetailView(itemId: item.id)) {
                    WatchItemRow(item: item)
                }
            }

            if itemStore.items(for: mode).isEmpty {
                Text("watch.item.list.empty")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(mode.displayName)
    }
}
