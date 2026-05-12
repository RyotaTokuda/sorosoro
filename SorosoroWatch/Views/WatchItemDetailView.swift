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
                    HStack {
                        statusIcon(item)
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.headline)
                            statusText(item)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        detailRow("watch.detail.cycle.label", value: String(localized: "item.detail.days.value \(item.cycleDays)"))
                        detailRow("watch.detail.last.label", value: item.lastPurchaseDate.formatted(date: .abbreviated, time: .omitted))
                        detailRow("watch.detail.next.label", value: item.nextDueDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    .font(.caption)

                    Divider()

                    Button {
                        showingPurchaseConfirm = true
                    } label: {
                        Label("action.purchased", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding(.horizontal)
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .alert("alert.purchase.complete.title", isPresented: $showingPurchaseConfirm) {
                Button("common.cancel", role: .cancel) {}
                Button("action.purchased") {
                    itemStore.markPurchased(id: item.id)
                    shoppingListStore.removeEntries(for: item.id)
                    WatchSyncService.shared.sendMarkPurchased(itemId: item.id)
                }
            } message: {
                Text("alert.purchase.confirm.short \(item.name)")
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
            Text("status.overdue \(abs(item.daysRemaining))")
                .font(.caption)
                .foregroundStyle(.red)
        case .soon:
            Text("status.remaining \(item.daysRemaining)")
                .font(.caption)
                .foregroundStyle(.orange)
        case .ok:
            Text("status.remaining \(item.daysRemaining)")
                .font(.caption)
                .foregroundStyle(.green)
        }
    }

    private func detailRow(_ labelKey: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(labelKey)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}
