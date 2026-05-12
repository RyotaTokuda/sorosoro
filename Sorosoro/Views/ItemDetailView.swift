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
                if !suggestionDismissed, let suggested = item.suggestedCycleDays() {
                    cycleSuggestionSection(item: item, suggested: suggested)
                }

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

                Section("item.detail.section.detail") {
                    HStack {
                        Text("item.detail.cycle")
                        Spacer()
                        Text("item.detail.days.value \(item.cycleDays)")
                    }
                    HStack {
                        Text("item.detail.last.purchase")
                        Spacer()
                        Text(item.lastPurchaseDate, style: .date)
                    }
                    if !item.memo.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("item.detail.memo")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(item.memo)
                        }
                    }
                }

                if !item.purchaseHistory.isEmpty {
                    Section("item.detail.history.title \(item.purchaseHistory.count)") {
                        ForEach(item.purchaseHistory.sorted().reversed(), id: \.self) { date in
                            Text(date, style: .date)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("item.detail.section.notification") {
                    HStack {
                        Text("item.detail.section.notification")
                        Spacer()
                        Text(item.notificationEnabled ? "ON" : "OFF")
                            .foregroundStyle(item.notificationEnabled ? .green : .secondary)
                    }
                    if item.notificationEnabled {
                        HStack {
                            Text("item.detail.notification.timing")
                            Spacer()
                            Text("item.detail.notification.days.before \(item.notificationDaysBefore)")
                        }
                    }
                }

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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("common.edit") { showingEditSheet = true }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                NavigationStack {
                    ItemFormView(mode: item.mode, editingItem: item)
                }
            }
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

    // MARK: - Suggestion Banner

    @ViewBuilder
    private func cycleSuggestionSection(item: Item, suggested: Int) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text("suggestion.title")
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
                Text("suggestion.body \(item.purchaseHistory.count) \(suggested) \(item.cycleDays)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button {
                        applysuggestion(to: item, days: suggested)
                    } label: {
                        Text("suggestion.apply \(suggested)")
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
                        Text("suggestion.dismiss")
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
            Text("status.overdue.label").foregroundStyle(.red).fontWeight(.semibold)
        case .soon:
            Text("status.soon.label").foregroundStyle(.orange).fontWeight(.semibold)
        case .ok:
            Text("status.ok.label").foregroundStyle(.green)
        }
    }
}
