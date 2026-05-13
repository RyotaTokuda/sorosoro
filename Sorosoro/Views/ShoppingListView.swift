import SwiftUI

struct ShoppingListView: View {
    @Environment(ItemStore.self) private var itemStore
    @Environment(ShoppingListStore.self) private var shoppingListStore
    @Environment(PlanService.self) private var planService
    @Environment(SettingsStore.self) private var settingsStore

    var body: some View {
        List {
            let urgentItems = filteredUrgentItems
            if !urgentItems.isEmpty {
                Section("shopping.urgent.section") {
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

            let unchecked = shoppingListStore.uncheckedEntries
            if !unchecked.isEmpty {
                Section("shopping.list.section") {
                    ForEach(unchecked) { entry in
                        if let item = itemStore.item(by: entry.itemId) {
                            ShoppingRowView(entry: entry, item: item)
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    NavigationLink(destination: ItemDetailView(itemId: item.id)) {
                                        Label("common.edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                }
            }

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
                        Text("shopping.checked.section")
                        Spacer()
                        Button("shopping.clear") {
                            shoppingListStore.clearChecked()
                        }
                        .font(.caption)
                    }
                }
            }

            if urgentItems.isEmpty && unchecked.isEmpty && checked.isEmpty {
                ContentUnavailableView {
                    Label("shopping.empty.title", systemImage: "cart")
                } description: {
                    Text("shopping.empty.description")
                }
            }
        }
        .navigationTitle("shopping.list.section")
    }

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
        .alert("alert.purchase.complete.title", isPresented: $showingConfirm) {
            Button("common.cancel", role: .cancel) {}
            Button("action.purchased") {
                itemStore.markPurchased(id: item.id)
                if let updatedItem = itemStore.item(by: item.id) {
                    NotificationService.scheduleNotification(for: updatedItem)
                }
                shoppingListStore.checkEntry(id: entry.id)
            }
        } message: {
            Text("alert.purchase.confirm.short \(item.name)")
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
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
