import SwiftUI

struct ItemListView: View {
    let mode: Mode
    @Environment(ItemStore.self) private var itemStore
    @Environment(PlanService.self) private var planService
    @Environment(SettingsStore.self) private var settingsStore
    @State private var showingAddSheet = false
    @State private var showingTemplatePicker = false
    @State private var showingPaywall = false

    private var items: [Item] {
        itemStore.items(for: mode)
    }

    private var isFreeInactiveMode: Bool {
        !planService.canUseAllModes() && mode != settingsStore.settings.selectedMode
    }

    var body: some View {
        List {
            if isFreeInactiveMode {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.blue)
                    Text("item.list.mode.switch.hint")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color(.systemGray6))
            }
            if items.isEmpty {
                ContentUnavailableView {
                    Label("item.list.empty.title", systemImage: "tray")
                } description: {
                    Text("item.list.empty.description")
                }
            } else {
                ForEach(items) { item in
                    NavigationLink(destination: ItemDetailView(itemId: item.id)) {
                        ItemRowView(item: item)
                    }
                }
                .onDelete(perform: deleteItems)
            }
        }
        .navigationTitle(mode.displayName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        if planService.canAddItem(currentCount: itemStore.itemCount(for: mode)) {
                            showingAddSheet = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        Label("item.list.add.new", systemImage: "plus")
                    }
                    Button {
                        if planService.canAddItem(currentCount: itemStore.itemCount(for: mode)) {
                            showingTemplatePicker = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        Label("item.list.add.template", systemImage: "doc.on.doc")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                ItemFormView(mode: mode)
            }
        }
        .sheet(isPresented: $showingTemplatePicker) {
            NavigationStack {
                TemplatePickerView(mode: mode)
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            NotificationService.cancelNotification(for: item.id)
            itemStore.deleteItem(id: item.id)
        }
    }
}

// MARK: - Row

struct ItemRowView: View {
    let item: Item

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body)
                    .fontWeight(.medium)
                Text("item.row.cycle.days \(item.cycleDays)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                statusBadge
                Text(item.nextDueDate, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch item.status {
        case .overdue:
            Text("status.overdue \(abs(item.daysRemaining))")
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.red.opacity(0.15))
                .foregroundStyle(.red)
                .clipShape(Capsule())
        case .soon:
            Text("status.remaining \(item.daysRemaining)")
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.orange.opacity(0.15))
                .foregroundStyle(.orange)
                .clipShape(Capsule())
        case .ok:
            Text("status.remaining \(item.daysRemaining)")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.green.opacity(0.1))
                .foregroundStyle(.green)
                .clipShape(Capsule())
        }
    }
}
